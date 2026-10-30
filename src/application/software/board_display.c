#include "board_display.h"
#include "board_focus.h"
#include "visual_tracker.h"
#include "ssd_fast.h"
#include "visual_detection_policy.h"
#include "network_service.h"
#include <stdio.h>
#include <string.h>
#include <math.h>
#define OSD_BASE 0x41210000u
volatile unsigned board_network_preview=1; /* Send camera frames to the PC monitor by default. */
volatile unsigned board_osd_commits,board_osd_visible,board_osd_class,board_osd_result_sequence;
static fusion_result latest;static uint64_t result_time,last_update;
static const char *const labels[60]={"AMECRO","AMEGFI","AMEKES","AMERED","AMEROB","BALORI","BARSWA","BKCCHI","BLUJAY","BTBWAR","CAMWAR","CANGOO","CEDWAX","CHISPA","CHSWAR","COMGRA","COMRAV","COMRED","COOHAW","DAEJUN","DOWWOO","EASPHO","EURSTA","FOXSPA","GRBHER3","GRHOWL","GRNHER","GRYCAT","HAIWOO","HOOMER","HOUFIN","HOUWRE","KILLDE","MALLAR3","MOUDOV","NORCAR","NORFLI","NORPAR","OVENBI1","PILWOO","PURFIN","REBWOO","REEVIR1","RETHAW","REWBLA","ROBGRO","RTHHUM","RUSBLA","SCATAN","SHSHAW","SONSPA","TRESWA","TUFTIT","WHBNUT","WHCSPA","WHTSPA","WOODUC","YEBSAP","YELWAR","YERWAR"};
void board_display_result(const fusion_result *r,uint64_t now){latest=*r;result_time=now;board_osd_result_sequence=r->sequence;}
void board_display_poll(uint64_t now){
 uint32_t t[16];char text[65],line[96];unsigned box[4]={0};
 if(now-last_update<33000u || platform_mmio_read(OSD_BASE+12u)&1u)return;
 last_update=now;visual_tracker_status(t,now);
 unsigned valid=t[2] && t[10]>VISUAL_BIRD_MIN_SCORE_Q6 && t[11]<=1000u;
 for(unsigned i=0;i<4;i++)box[i]=(t[12+i]+500u)/1000u;
 valid=valid && box[0]<box[2] && box[1]<box[3] && box[2]<=1920 && box[3]<=1080;
 uint64_t confirmation=now>=(uint64_t)t[6]*1000u?now-(uint64_t)t[6]*1000u:0;
 unsigned classified=valid && result_time && now>=result_time && now-result_time<=8000000u &&
  latest.video_timestamp_us+2000u>=confirmation &&
  !latest.error && latest.image_top1<60 && isfinite(latest.confidence) && latest.confidence>=0 && latest.confidence<=1;
 float candidate[4],candidate_score=0;
 unsigned provisional=!valid && ssd_fast_view(now,candidate,&candidate_score);
 if(provisional)for(unsigned i=0;i<4;i++)box[i]=(unsigned)(candidate[i]+.5f);
 if(board_focus_searching())snprintf(line,sizeof line,"OPTICAL FOCUS SEARCH %u",board_focus_diag[3]);
 else if(classified)snprintf(line,sizeof line,"%s classification:%u%% possiblity:%u%%",labels[latest.image_top1],(unsigned)(latest.confidence*100.f+.5f),t[10]/10000u);
 else if(valid)snprintf(line,sizeof line,"BIRD possiblity:%u%% CLASSIFYING",t[10]/10000u);
 else if(provisional)snprintf(line,sizeof line,"CANDIDATE possiblity:%u%% VERIFYING",(unsigned)(candidate_score*100.f+.5f));
 else if(latest.error)snprintf(line,sizeof line,"BOARD ERROR %d",latest.error);
 else snprintf(line,sizeof line,"BOARD VISUAL: SEARCHING BIRD");
 memset(text,' ',64);text[64]=0;size_t n=strlen(line);if(n>64)n=64;memcpy(text,line,n);
 platform_mmio_write(OSD_BASE+16u,box[0]|(box[1]<<16));
 platform_mmio_write(OSD_BASE+20u,box[2]|(box[3]<<16));
 platform_mmio_write(OSD_BASE+24u,valid || provisional);
 for(unsigned i=0;i<16;i++){uint32_t word=0;for(unsigned j=0;j<4;j++)word|=(uint32_t)(unsigned char)text[i*4+j]<<(j*8);platform_mmio_write(OSD_BASE+32u+i*4u,word);}
 platform_mmio_write(OSD_BASE+4u,1u);
 board_osd_commits++;board_osd_visible=valid;board_osd_class=classified?latest.image_top1:0xffffffffu;
}
