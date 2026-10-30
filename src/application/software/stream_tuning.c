#include "stream_tuning.h"
#include "servo_tracking.h"
#include <math.h>
#include <string.h>
static float preview_fps=2.5f;
static uint32_t revision=1u,ack_request,ack_status,applies,next_cache;
static struct {uint8_t payload[22];uint32_t request,status,valid;} cache[16];
static uint32_t be32(const uint8_t *p) {
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
void stream_tuning_init(void) {
    preview_fps=2.5f;revision=1u;ack_request=ack_status=applies=next_cache=0;
    memset(cache,0,sizeof cache);
}
uint32_t stream_preview_interval_us(void) {
    return (uint32_t)ceilf(1000000.f/preview_fps);
}
int stream_tuning_command(uint32_t boot,const uint8_t *p,unsigned bytes) {
    if(!p || bytes!=22u)return -1;
    uint32_t request=be32(p+10),status=0;ack_request=request;
    if(p[0]!=25u || p[1]!=1u){ack_status=2u;return -1;}
    if(!boot || be32(p+2)!=boot){ack_status=3u;return -1;}
    if(!request){ack_status=5u;return -1;}
    for(unsigned i=0;i<16;i++)if(cache[i].valid && cache[i].request==request) {
        status=memcmp(cache[i].payload,p,22u)?6u:cache[i].status;
        if(status==1u)status=7u;
        ack_status=status;return status==7u?0:-1;
    }
    float values[2];
    for(unsigned i=0;i<2;i++){uint32_t bits=be32(p+14+4u*i);memcpy(values+i,&bits,4);}
    if(!isfinite(values[0]) || values[0]<.5f || values[0]>10.f ||
       !isfinite(values[1]) || values[1]<1.f || values[1]>4.f)status=5u;
    if(be32(p+6)!=revision || revision==UINT32_MAX)status=4u;
    if(!status) {
        if(servo_tracking_configure_scan_rate(values[0]))status=8u;
        else {preview_fps=values[1];revision++;applies++;status=1u;}
    }
    unsigned index=next_cache++&15u;
    memcpy(cache[index].payload,p,22u);cache[index].request=request;
    cache[index].status=status;cache[index].valid=1u;
    ack_status=status;return status==1u?0:-1;
}
void stream_tuning_status(uint32_t words[16],uint32_t boot) {
    memset(words,0,16u*sizeof *words);words[0]=0x53434e32u;words[1]=1u;
    words[2]=revision;words[3]=ack_request;words[4]=ack_status;words[5]=boot;
    float scan=servo_tracking_scan_rate();
    memcpy(words+6,&scan,4);memcpy(words+7,&preview_fps,4);words[8]=applies;
    servo_tracking_scan_timing(words+9);words[11]=stream_preview_interval_us();
}
