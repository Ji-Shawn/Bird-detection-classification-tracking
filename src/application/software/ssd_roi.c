#include "ssd_roi.h"
#include "fusion_math.h"
#include <math.h>
#include <stddef.h>
#include <stdint.h>

static float roi_normalized[3][256];
static unsigned roi_tables_ready;

static int valid_dimensions(int width,int height){
    return width>=2&&height>=2&&width<=4096&&height<=4096;
}
static int valid_roi(const ssd_roi_box *roi,int width,int height){
    if(!roi||!valid_dimensions(width,height)||roi->side<2||
       roi->side>width||roi->side>height||roi->x<0||roi->y<0)return 0;
    /* Subtractions avoid overflowing caller-supplied x+side/y+side. */
    return roi->x<=width-roi->side&&roi->y<=height-roi->side;
}
int ssd_roi_from_box(const float hint[4],int width,int height,ssd_roi_box *out){
    if(!hint||!out||!valid_dimensions(width,height))return 0;
    for(unsigned i=0;i<4;i++)if(!isfinite(hint[i]))return 0;
    if(hint[0]<0||hint[1]<0||hint[2]>width||hint[3]>height)return 0;
    float w=hint[2]-hint[0],h=hint[3]-hint[1];
    if(w<8.f||h<8.f)return 0;
    int limit=width<height?width:height;
    float extent=fmaxf(w,h);
    if(extent>limit)return 0; /* The square must not cut the hinted bird. */
    int side=(int)ceilf(extent*1.8f),minimum=limit<192?limit:192;
    if(side<minimum)side=minimum;
    if(side>limit)side=limit;
    int x=(int)floorf((hint[0]+hint[2]-side)*.5f);
    int y=(int)floorf((hint[1]+hint[3]-side)*.5f);
    if(x<0)x=0;
    if(y<0)y=0;
    if(x>width-side)x=width-side;
    if(y>height-side)y=height-side;
    ssd_roi_box candidate={x,y,side};
    if(!valid_roi(&candidate,width,height))return 0;
    /* A nearly maximal fractional hint can require one more integer pixel
     * than the available square. Do not silently trim that target. */
    if(x>hint[0]||y>hint[1]||x+side<hint[2]||y+side<hint[3])return 0;
    *out=candidate;return 1;
}
int ssd_roi_map(const ssd_roi_box *roi,const float box320[4],int width,int height,float mapped[4]){
    if(!mapped||!box320||!valid_roi(roi,width,height))return 0;
    for(unsigned i=0;i<4;i++)if(!isfinite(box320[i]))return 0;
    if(box320[0]<0||box320[1]<0||box320[2]>320.f||box320[3]>320.f||
       box320[2]<=box320[0]||box320[3]<=box320[1])return 0;
    float scale=(float)roi->side/320.f;
    float candidate[4]={roi->x+box320[0]*scale,roi->y+box320[1]*scale,
                        roi->x+box320[2]*scale,roi->y+box320[3]*scale};
    if(candidate[0]<0||candidate[1]<0||candidate[2]>width||candidate[3]>height||
       candidate[2]-candidate[0]<8.f||candidate[3]-candidate[1]<8.f)return 0;
    for(unsigned i=0;i<4;i++)mapped[i]=candidate[i];
    return 1;
}
static int expanded_rgb(uint16_t p,int c){
    int v=c==0?(p>>11):c==1?((p>>5)&63):(p&31);
    return c==1?((v<<2)|(v>>4)):((v<<3)|(v>>2));
}
static void prepare_roi_tables(void){
    if(roi_tables_ready)return;
    const float mean[3]={.485f,.456f,.406f},std[3]={.229f,.224f,.225f};
    for(int c=0;c<3;c++)for(int p=0;p<256;p++){
        /* Keep the exact operation order and float constants of the deployed
         * scalar SSD reference. This is not the image classifier's filter. */
        roi_normalized[c][p]=((float)p/255.0f-mean[c])/std[c];
        if(!(p&63))fusion_yield();
    }
    roi_tables_ready=1;
}
static int8_t quantize_roi(float v){
    float scaled=v/0.01865844987332821f;
    int t=(int)floorf(scaled);float fraction=scaled-t;
    int q=t+(fraction>.5f||(fraction==.5f&&(t&1)))-14;
    return (int8_t)(q< -128?-128:q>127?127:q);
}
int ssd_roi_input(const uint16_t *full,int width,int height,const ssd_roi_box *roi,int8_t *out){
    if(!full||!out||!valid_roi(roi,width,height))return -1;
    /* Commands may run at fusion_yield. Keep this job's geometry immutable
     * even if its caller stores subsequent ROI requests in the same object. */
    ssd_roi_box snapshot=*roi;roi=&snapshot;
    uintptr_t source=(uintptr_t)full,dest=(uintptr_t)out;
    size_t source_bytes=(size_t)width*(size_t)height*sizeof *full;
    const size_t output_bytes=320u*320u*3u;
    if(source>UINTPTR_MAX-source_bytes||dest>UINTPTR_MAX-output_bytes||
       (source<dest+output_bytes&&dest<source+source_bytes))return -1;
    prepare_roi_tables();
    int side=roi->side,left[320],right[320];float dxs[320];
    for(int x=0;x<320;x++){
        float fx=fmaxf(0,(x+.5f)*((float)side/320)-.5f);
        left[x]=(int)fx;right[x]=left[x]+1<side?left[x]+1:left[x];dxs[x]=fx-left[x];
    }
    for(int y=0;y<320;y++){
        fusion_yield();
        float fy=fmaxf(0,(y+.5f)*((float)side/320)-.5f);
        int y0=(int)fy,y1=y0+1<side?y0+1:y0;float dy=fy-y0;
        const uint16_t *row0=full+(roi->y+y0)*width+roi->x;
        const uint16_t *row1=full+(roi->y+y1)*width+roi->x;
        for(int x=0;x<320;x++){
            int x0=left[x],x1=right[x];float dx=dxs[x];
            for(int c=0;c<3;c++){
                float a=roi_normalized[c][expanded_rgb(row0[x0],c)],b=roi_normalized[c][expanded_rgb(row0[x1],c)];
                float d=roi_normalized[c][expanded_rgb(row1[x0],c)],e=roi_normalized[c][expanded_rgb(row1[x1],c)];
                float v=(1-dy)*((1-dx)*a+dx*b)+dy*((1-dx)*d+dx*e);
                out[(y*320+x)*3+c]=quantize_roi(v);
            }
        }
    }
    return 0;
}
