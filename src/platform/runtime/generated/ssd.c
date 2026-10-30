#include "runtime.h"
/* SSD sample0 acceptance runtime: frozen 98-node DAG, independent output buffers.
 * Generated helper transport is derived from the verified mode-6 audio harness.
 * The board has not executed this ELF. Use drive_ssd.tcl only after PS/PL preflight.
 */
#include <string.h>
#include "xparameters.h"
#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "ps_math.h"
#include "ssd_table.h"
#include "hardware_helpers.h"
#include "ssd_dw_layout.h"

static int run_dw(const ssd_layer *L, u32 input, u32 output) {
    const conv_spec *s=&L->spec;
    int s2=s->stride==2, weng=s2?((s->w+1)&~1):(s->w<3?3:s->w);
    int front=weng+1, tail=s2?((s->h&1)?weng:0):weng+1;
    int ntot=front+s->h*weng+tail, skip=s2?0:2*(weng+1), C=s->ci;
    int physical=s2?s->oh*s->ow:ntot;
    ssd_dw_pad((unsigned char *)STAGE,front,s->h,s->w,weng,tail,C,s->xzp);
    for(int r=0;r<s->h;r++) {
        if(!(r&3))fusion_yield();
        memcpy((void *)(STAGE+(front+r*weng)*C),(void *)(input+r*s->w*C),s->w*C);
    }
    Xil_DCacheFlushRange(STAGE,ntot*C);
    int status=eng_cfg(0,s->mul,s->shift,s->xzp,s->yzp,ntot,C,weng,0,C*9/8,C/2,s2,DMA_MAXB/C);
    if(status) return status;
    status=push_hdr(L->waddr,C*9,L->baddr,C*4);
    if(status) return status;
    status=run_pixels(STAGE,OUTBUF,ntot,s->oh*s->ow,C,C,s2,DMA_MAXB/C);
    if(status) return status;
    Xil_DCacheInvalidateRange(OUTBUF,physical*C);
    for(int r=0;r<s->oh;r++) {
        if(!(r&3))fusion_yield();
        memcpy((void *)(output+r*s->ow*C),(void *)(OUTBUF+(skip+r*(s2?s->ow:weng))*C),s->ow*C);
    }
    return 0;
}

static int run_pw(int li,const ssd_layer *L,u32 input,u32 output) {
    const conv_spec *s=&L->spec;
    int tile=256,npix=s->h*s->w;
    while(tile>16 && s->ci*tile>65536) tile-=16;
    if(tile>s->co) tile=s->co;
    for(int o=0;o<s->co;o+=tile) {
        int ct=s->co-o<tile?s->co-o:tile;
        int status=eng_cfg(1,s->mul,s->shift,s->xzp,s->yzp,npix,s->ci,0,ct,s->ci*ct/8,ct/2,0,0);
        if(status) return status;
        diag_snap(li,o,1,0);
        status=push_hdr(L->waddr+o*s->ci,s->ci*ct,L->baddr+o*4,ct*4);
        if(status) {diag_snap(li,o,2,status);return status;}
        diag_snap(li,o,3,0);
        int direct=tile==s->co;
        u32 dma_output=direct?output:OUTBUF;
        status=run_pixels_pw_overlap(input,dma_output,npix,s->ci,ct);
        if(status) {diag_snap(li,o,4,status);return status;}
        Xil_DCacheInvalidateRange(dma_output,npix*ct);
        if(!direct) for(int p=0;p<npix;p++) {
            if(!(p&63))fusion_yield();
            memcpy((void *)(output+p*s->co+o),(void *)(OUTBUF+p*ct),ct);
        }
        diag_snap(li,o,5,0);
    }
    return 0;
}

static void compare(u32 output,u32 expected,int n,volatile u32 *res) {
    const s8 *a=(const s8 *)output,*b=(const s8 *)expected;
    res[0]=n;res[1]=0;res[2]=0;res[3]=0xFFFFFFFFu;
    Xil_DCacheInvalidateRange(expected,n);
    for(int i=0;i<n;i++) {
        int d=(int)a[i]-(int)b[i];
        if(d) {
            if(d<0) d=-d;
            if(!res[1]) res[3]=i;
            res[1]++;
            if((u32)d>res[2]) res[2]=d;
        }
    }
}

int ssd_run(void) {
    int failure=0,chain=0;
    Xil_DCacheInvalidateRange((u32)MB,64);
    if(MB[0]!=0x53534431u || MB[6]>1 || MB[7]!=0x4D454D43u) {failure=-100;goto finish;}
    chain=MB[6];
    memset((void *)RESTAB,0xDE,98*16);
    memset((void *)CHRES,0,256*4);
    CHRES[0]=0x53534431u;CHRES[1]=chain;
    XAxiDma_Config *cfg=fusion_dma_config();
    if(!cfg) {failure=-101;goto finish;}
    if(XAxiDma_CfgInitialize(&Dma,cfg)!=XST_SUCCESS || XAxiDma_HasSg(&Dma)) {failure=-102;goto finish;}
    ccnt_enable();
    for(int li=0;li<98;li++) { fusion_yield();
        const ssd_layer *L=&SSD_LAYERS[li];
        const conv_spec *s=&L->spec;
        volatile u32 *res=RESTAB+li*4;
        u32 input=chain?L->chain_a:L->gold_a;
        u32 input_b=chain?L->chain_b:L->gold_b;
        u32 t0=ccnt();
        CHRES[2]=li;
        Xil_DCacheInvalidateRange(input,L->inbytes);
        if(L->typ==3) Xil_DCacheInvalidateRange(input_b,L->outbytes);
        if(L->typ!=3) {
            Xil_DCacheInvalidateRange(L->waddr,L->wbytes);
            Xil_DCacheInvalidateRange(L->baddr,s->co*4);
        }
        if(L->typ==0) ps_conv(s,(const int8_t *)input,(const int8_t *)L->waddr,(const int32_t *)L->baddr,(int8_t *)L->output);
        else if(L->typ==3) ps_add(L->outbytes,(const int8_t *)input,(const int8_t *)input_b,(int8_t *)L->output,L->sa,L->sb,L->sy,L->azp,L->bzp,s->yzp);
        else if(L->typ==2) failure=run_dw(L,input,L->output);
        else failure=run_pw(li,L,input,L->output);
        CHRES[132+li]=ccnt()-t0; /* compute, staging, DMA; excludes comparison */
        if(failure) {res[0]=0;res[1]=0xFFFFFFFFu;res[2]=0;res[3]=(u32)failure;dma_recover();goto finish;}
        Xil_DCacheFlushRange(L->output,L->outbytes);
        if (unified_validate) compare(L->output,L->expected,L->outbytes,res);
        else { res[0]=L->outbytes; res[1]=res[2]=0; res[3]=0xFFFFFFFFu; }
        CHRES[32+li]=ccnt()-t0;
        Xil_DCacheFlushRange((u32)res,16);
        if(res[1]) {failure=-103;goto finish;}
        CHRES[3]=li+1;
    }
    if(chain) {
        ssd_head heads[6];
        for(int i=0;i<6;i++) {
            const ssd_head_ref *h=&SSD_HEADS[i];
            heads[i]=(ssd_head){(const int8_t *)h->cls,(const int8_t *)h->box,h->h,h->w,16,h->cs,h->bs,h->cz,h->bz};
        }
        u32 t0=ccnt();
        int n=ssd_postprocess(heads,&SSD_ANCHORS[0][0],(ssd_detection *)0x2F002000u);
        CHRES[4]=(u32)n;CHRES[5]=ccnt()-t0;
        if(n<0) {failure=-104;goto finish;}
        Xil_DCacheFlushRange(0x2F002000u,n*sizeof(ssd_detection));
    }
finish:
    CHRES[6]=(u32)failure;
    Xil_DCacheFlushRange((u32)RESTAB,98*16);
    Xil_DCacheFlushRange((u32)CHRES,256*4);
    MB[12]=(u32)failure;MB[13]=failure?0xBAD0u:0x600Du;
    Xil_DCacheFlushRange((u32)MB,64);
    return failure?1:0;
}
