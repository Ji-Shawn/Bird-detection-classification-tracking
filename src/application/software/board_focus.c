#include "board_focus.h"
#include "visual_detection_policy.h"
#include "bird_focus.h"
#include "camera_recovery.h"
#include "network_service.h"
#include <string.h>
#include <math.h>
volatile uint32_t board_focus_diag[12];
volatile uint32_t board_focus_trace[64];
static unsigned roi[4]={768,432,1152,648};
static unsigned roi_generation,frame_generation,frame_valid;
static uint64_t frame_stamp,last_poll,scan_deadline,last_track_capture;
static uint32_t last_track_sequence;
static uint64_t sum,sum2,energy;static unsigned count,frame_seq,quality,texture_valid;
static unsigned state,pending=1,owns,suspended,own_sequence,original,best,best_quality,baseline;
static unsigned phase,index_,coarse_best,settle_sequence,measure_sequence,measure_count;
static uint64_t measure_sum,deadline,last_end,settle_after;
static unsigned baseline_count,baseline_sequence;
static uint64_t baseline_sum;
static unsigned local_request,accepted,locked_quality,locked_mean,blur_frames;
static unsigned local_wide;
static unsigned tile_sum[16],tile_count[16];
static int scene[16],scene_previous[16],scene_reference[16];
static unsigned have_scene,have_reference,scene_stable;
static unsigned recovery_seen,recovery_wait;
static uint64_t stable_until,blur_since;
static float previous[4],desired[4],scan_box[4],focused_box[4];
static unsigned hits,have_desired,have_focused,scan_target;
static const unsigned coarse[9]={0,128,256,384,512,640,768,896,1023};
unsigned board_focus_searching(void){return state!=0;}
void board_focus_frame_begin(void){frame_generation=roi_generation;sum=sum2=energy=0;count=0;memset(tile_sum,0,sizeof tile_sum);memset(tile_count,0,sizeof tile_count);}
static int green5(const uint16_t *p){
 return ((p[-2]>>5)&63)+((p[-1]>>5)&63)+((p[0]>>5)&63)+((p[1]>>5)&63)+((p[2]>>5)&63);
}
void board_focus_frame_chunk(const void *pixels,unsigned offset,unsigned bytes){
 if(bytes<6)return;
 const uint16_t *p=(const uint16_t *)pixels;unsigned first=offset/2,end=first+bytes/2;
 unsigned y0=first/1920,yend=(end-1)/1920;
 for(unsigned y=y0;y<=yend;y++){
  if(y<roi[1]||y>=roi[3]||y%4)continue;
  for(unsigned x=(roi[0]+3)&~3u;x<roi[2];x+=4){
   unsigned a=y*1920+x;if(x<8||x+8>=1920||a<first+6||a+6>=end)continue;
   const uint16_t *v=p+a-first;int g=(v[0]>>5)&63;
   /* Five-pixel spatial means suppress single-pixel noise before measuring
    * image detail at a four-pixel spacing. No display filtering is applied. */
   int e=2*green5(v)-green5(v-4)-green5(v+4);
   e=e<0?-e:e;e=e>15?e-15:0;
   energy+=(unsigned)(e*e);sum+=g;sum2+=(unsigned)(g*g);count++;
   unsigned tile=((y-roi[1])*4/(roi[3]-roi[1]))*4+(x-roi[0])*4/(roi[2]-roi[0]);
   tile_sum[tile]+=g;tile_count[tile]++;
  }
 }
}
void board_focus_frame_end(uint64_t now){
 /* Repeated delivery/polling of one timestamp is never a second sample. */
 if(frame_stamp&&now<=frame_stamp)return;
 frame_stamp=now;
 frame_seq++;
 frame_valid=frame_generation==roi_generation;
 if(!frame_valid){texture_valid=quality=scene_stable=0;return;}
 /* Native green-channel variance must exceed the measured flat-scene noise. */
 texture_valid=count>=64 && sum/count>=4 && sum2*count>sum*sum+12ull*count*count;
 quality=texture_valid?(unsigned)(energy*256u/(25u*count)):0;
 int scene_mean=0,prev_mean=0,ref_mean=0,motion=0,change=0;
 unsigned scene_valid=1;
 for(unsigned i=0;i<16;i++){
  if(!tile_count[i]){scene_valid=0;break;}
  scene[i]=(int)(tile_sum[i]/tile_count[i]);scene_mean+=scene[i];
  prev_mean+=scene_previous[i];ref_mean+=scene_reference[i];
 }
 if(scene_valid){
  scene_mean/=16;prev_mean/=16;ref_mean/=16;
  for(unsigned i=0;i<16;i++){
   int d=scene[i]-scene_mean-scene_previous[i]+prev_mean;motion+=d<0?-d:d;
   d=scene[i]-scene_mean-scene_reference[i]+ref_mean;change+=d<0?-d:d;
  }
  scene_stable=have_scene&&motion<=32?scene_stable+1:0;
  if(!have_reference&&!state){memcpy(scene_reference,scene,sizeof scene);have_reference=1;}
  /* This trigger needs no detected bird: severe blur may prevent SSD from
   * producing a box. Ignore uniform exposure shifts and wait for a stable view. */
  /* A different layout is not evidence of defocus. After obtaining a
   * reference, retain the lens unless stable same-scene detail really falls. */
  if(!state&&!locked_quality&&have_reference&&texture_valid&&scene_stable>=3&&change>=96&&!pending){pending=1;local_request=2;}
  memcpy(scene_previous,scene,sizeof scene);have_scene=1;
 }
 /* Blur recovery also works before the first successful bird detection. */
 if(!state&&scene_valid&&change<=48&&scene_stable>=3&&texture_valid&&locked_quality&&count&&
    (sum/count)*4>=locked_mean*3&&(sum/count)*4<=locked_mean*5){
  if(quality*100u<locked_quality*55u){if(!blur_frames)blur_since=now;blur_frames++;}
  else blur_frames=0;
  /* A brief occlusion/exposure transient must not launch a lens search. */
  if(blur_frames>=8&&now>=blur_since&&now-blur_since>=1800000u&&!pending&&
     (!last_end||(now>=last_end&&now-last_end>=8000000u))){pending=1;local_request=2;blur_frames=0;}
 }else blur_frames=0;
 board_focus_diag[0]=0x4d323946;board_focus_diag[1]=state;board_focus_diag[4]=best;
 board_focus_diag[5]=best_quality;board_focus_diag[6]=quality;board_focus_diag[7]=frame_seq;
 board_focus_diag[10]=baseline;board_focus_diag[11]=phase*16+index_;
 platform_cache_flush((const void *)board_focus_diag,sizeof board_focus_diag);
}
static float overlap(const float *a,const float *b){
 float w=fmaxf(0,fminf(a[2],b[2])-fmaxf(a[0],b[0]));
 float h=fmaxf(0,fminf(a[3],b[3])-fmaxf(a[1],b[1]));
 float u=(a[2]-a[0])*(a[3]-a[1])+(b[2]-b[0])*(b[3]-b[1])-w*h;
 return u>0?w*h/u:0;
}
void board_focus_observe(float score,const float b[4],uint64_t now){
 if(!isfinite(score)||score<.45f||score>1.f){hits=0;stable_until=0;return;}
 for(unsigned i=0;i<4;i++)if(!isfinite(b[i]))return;
 if(b[0]<0||b[1]<0||b[2]>1920||b[3]>1080||b[2]-b[0]<8||b[3]-b[1]<8)return;
 hits=hits&&overlap(previous,b)>.7f?hits+1:1;memcpy(previous,b,sizeof previous);
 if(hits<2){stable_until=0;return;}
 memcpy(desired,b,sizeof desired);have_desired=1;
 if(!have_focused){pending=1;local_request=1;}
 stable_until=now+5000000u;
}
void board_focus_track(float score,const float b[4],uint32_t sequence,
                       uint64_t captured,uint64_t now){
 if(!captured||captured>now||now-captured>500000u||
    captured<=last_track_capture||(last_track_capture&&sequence==last_track_sequence))return;
 if(!isfinite(score)||score<=VISUAL_BIRD_MIN_SCORE||score>1.f)return;
 for(unsigned i=0;i<4;i++)if(!isfinite(b[i]))return;
 if(b[0]<0||b[1]<0||b[2]>1920||b[3]>1080||b[2]-b[0]<8||b[3]-b[1]<8)return;
 last_track_capture=captured;last_track_sequence=sequence;
 memcpy(desired,b,sizeof desired);have_desired=1;stable_until=captured+500000u;
 if(state)return; /* The current scan's ROI and reference remain fixed. */
 /* Translation, pose and detector/NCC box size are not distance feedback.
  * Acquire the first target ROI once; subsequent automatic recovery requires
  * persistent same-scene sharpness loss above, never box motion alone. */
 if(!have_focused){pending=1;local_request=1;}
}
static void configure_roi(uint64_t now){
 roi_generation++;scan_target=have_desired&&now<stable_until;
 have_scene=scene_stable=0;
 if(scan_target)memcpy(scan_box,desired,sizeof scan_box);
 if(have_desired&&now<stable_until){
  int cx=(int)((desired[0]+desired[2])*.5f),cy=(int)((desired[1]+desired[3])*.5f);
  int w=(int)fminf(384,fmaxf(128,desired[2]-desired[0])),h=(int)fminf(384,fmaxf(128,desired[3]-desired[1]));
  int x=cx-w/2,y=cy-h/2;if(x<4)x=4;if(y<4)y=4;if(x+w>1916)x=1916-w;if(y+h>1076)y=1076-h;
  roi[0]=x;roi[1]=y;roi[2]=x+w;roi[3]=y+h;
 }else{roi[0]=768;roi[1]=432;roi[2]=1152;roi[3]=648;}
}
static int move_lens(unsigned target,uint64_t now){
 if(bird_focus_contrast_move(target))return -1;
 uint32_t m[6];bird_focus_manual_status(m);own_sequence=m[5];owns=1;
 board_focus_diag[3]=target;state=2;deadline=now+5000000u;return 0;
}
static unsigned fine_position(void){
 int step=phase==2?8:32,n=5;
 int start=(int)coarse_best-(n/2)*step;
 if(start<0)start=0;
 if(start+(n-1)*step>1023)start=1023-(n-1)*step;
 return (unsigned)(start+(int)index_*step);
}
static unsigned next_search_position(void){
 for(;;){
  if(!phase&&index_==9){phase=1;index_=0;coarse_best=best;}
  else if(phase==1&&index_==5){phase=2;index_=0;coarse_best=best;}
  else if(phase==5&&index_==5){
   index_=0;unsigned low=fine_position();index_=4;unsigned high=fine_position();index_=0;
   if((best!=original&&(best==low||best==high))||
      (local_wide&&best_quality<=baseline+baseline*12u/100u)){
    phase=0; /* The optimum lies beyond the local search, or blur persists. */
   }else{phase=2;coarse_best=best;}
  }
  else if(phase==2&&index_==5)return 1024u; /* Recheck original, then winner. */
  unsigned pos=phase?fine_position():coarse[index_];
  /* These positions already have the same fixed ROI's two-frame score:
   * local center uses this round's baseline; finer centers use their measured
   * winning anchor. Skip only identical DAC codes, including clipped edges.
   * Keep the final original/winner remeasurements to reject time drift. */
  if((phase==5&&pos==original)||((phase==1||phase==2)&&pos==coarse_best)){
   index_++;continue;
  }
  return pos;
 }
}
static void finish_scan(uint64_t now){
 state=0;last_end=now;pending=0;blur_frames=0;
 locked_quality=best_quality;locked_mean=count?(unsigned)(sum/count):0;
 memcpy(scene_reference,scene,sizeof scene);have_reference=1;scene_stable=0;
 board_focus_diag[9]=accepted;
 if(scan_target){memcpy(focused_box,scan_box,sizeof focused_box);have_focused=1;}
}
void board_focus_policy_poll(uint64_t now){
 uint32_t f[16],m[6];bird_focus_status(f,now);bird_focus_manual_status(m);
 if(recovery_seen!=ov5640_recovery_generation()){
  recovery_seen=ov5640_recovery_generation();recovery_wait=1;
  /* Sensor interruption invalidates every in-flight image/ROI score. Keep
   * the user's AF/manual choice and last held optical position; recovery
   * itself must never launch another autofocus sweep. */
  state=pending=local_request=owns=0;last_end=now;
  deadline=scan_deadline=0;roi_generation++;frame_valid=0;
  frame_stamp=last_track_capture=stable_until=0;hits=have_desired=0;
  measure_count=baseline_count=0;measure_sum=baseline_sum=0;
  blur_frames=have_scene=have_reference=scene_stable=0;
 }
 if(ov5640_recovery_busy()){last_poll=now;return;}
 if(recovery_wait){
  /* AF firmware reload and VCM restoration remain cooperative. No score
   * from before the sensor restart may enter a new focus decision. */
  if(f[2]==1||f[2]==7)return;
  recovery_wait=0;frame_valid=0;frame_stamp=0;roi_generation++;
  have_scene=have_reference=scene_stable=blur_frames=0;
  if(f[1]&&m[1]&&f[2]==8){owns=1;own_sequence=m[5];}
 }
 if(last_poll&&now<last_poll){
  /* Cancel this round rather than combine scores or extend its budget across
   * clock epochs. The driver safely finishes its current register target. */
  state=0;pending=1;local_request=1;last_end=last_poll=now;
  measure_count=baseline_count=0;measure_sum=baseline_sum=0;
  deadline=scan_deadline=0;roi_generation++;
  frame_stamp=last_track_capture=stable_until=0;frame_valid=0;hits=0;
  blur_frames=locked_quality=have_scene=have_reference=scene_stable=0;
  return;
 }
 last_poll=now;
 if((owns&&m[5]!=own_sequence)||!f[1]){state=0;owns=0;pending=0;suspended=1;return;}
 if(suspended){if(m[1]||!f[1])return;suspended=0;pending=1;local_request=0;last_end=0;}
 if(state&&(now>deadline||(state<5&&now>scan_deadline))){unsigned old_state=state;board_focus_diag[8]++;state=0;pending=0;last_end=now;if(old_state>=2&&old_state!=5&&old_state!=6&&owns&&f[2]!=5&&move_lens(original,now)==0)state=5;return;}
 unsigned fresh=frame_valid&&frame_stamp&&frame_stamp<=now&&now-frame_stamp<=500000u;
 if(state==0){
  if(owns&&!m[1]&&f[1]){owns=0;pending=1;local_request=0;last_end=0;}
  if(!pending||(last_end&&(now<last_end||now-last_end<(local_request?750000u:3000000u))))return;
  if(!fresh)return;
  if(!texture_valid){pending=local_request=0;return;}
  if(!((f[1]&&(f[2]==4||f[2]==6)&&!m[1])||(owns&&m[1]&&f[2]==8)))return;
  configure_roi(now);settle_sequence=frame_seq;baseline_sequence=frame_seq;baseline_count=0;baseline_sum=0;state=1;deadline=now+5000000u;scan_deadline=now+30000000u;return;
 }
 if(state==1){
  /* The first end boundary may belong to a partially collected old ROI. */
  if(!fresh||frame_seq-settle_sequence<2||scene_stable<2)return;
  if(!texture_valid){board_focus_diag[8]++;pending=1;local_request=0;state=0;last_end=now;return;}
  if(frame_seq==baseline_sequence)return;
  baseline_sequence=frame_seq;baseline_sum+=quality;
  if(++baseline_count<2)return;
  uint8_t hi,lo;if(ov5640_af_read(0x3603,&hi)||ov5640_af_read(0x3602,&lo)){board_focus_diag[8]++;pending=0;state=0;last_end=now;return;}
  original=((hi&63u)<<4)|(lo>>4);baseline=(unsigned)(baseline_sum/2u);best=original;best_quality=baseline;
  phase=5;index_=0;coarse_best=original;accepted=0;board_focus_diag[2]++;
  /* A first target can be far outside the previous scene's focus distance.
   * A flat local +/-64 DAC result is not evidence of a sharp image. Permit
   * one bounded coarse fallback, then retain the existing hold policy. */
  local_wide=local_request!=1 || !have_focused;
  memset((void *)board_focus_trace,0,sizeof board_focus_trace);
  board_focus_trace[0]=0x4d323954;board_focus_trace[1]=board_focus_diag[2];
  board_focus_trace[2]=baseline;board_focus_trace[3]=original;
  board_focus_trace[5]=local_request;
  local_request=0;
  platform_cache_flush((const void *)board_focus_trace,sizeof board_focus_trace);
  if(move_lens(next_search_position(),now)){state=0;pending=0;board_focus_diag[8]++;}return;
 }
 if(state==2){if(f[2]==5){state=0;pending=0;board_focus_diag[8]++;last_end=now;return;}if(f[2]!=8||m[4])return;settle_sequence=frame_seq;settle_after=now+70000u;state=3;return;}
 if(state==3){
  /* Use camera capture time, not delayed copy completion. One 15FPS sensor
   * interval after the verified final register pair excludes in-flight old
   * exposures; independent following frames provide the score. */
  if(!fresh||frame_stamp<settle_after||frame_seq-settle_sequence<1)return;
  measure_sequence=frame_seq;measure_count=0;measure_sum=0;state=4;return;
 }
 if(state==4){
  if(!fresh||frame_seq==measure_sequence||scene_stable<2)return;
  /* A deliberately defocused probe may lose texture. Score it as zero and
   * continue the bounded search so the opposite direction is still tested. */
  measure_sequence=frame_seq;
  measure_sum+=quality;measure_count++;if(measure_count<2)return;
  unsigned score=(unsigned)(measure_sum/measure_count),pos=board_focus_diag[3];
  unsigned record=board_focus_trace[4];
  if(record<29){board_focus_trace[6+record*2]=pos;board_focus_trace[7+record*2]=score;board_focus_trace[4]=record+1;platform_cache_flush((const void *)board_focus_trace,sizeof board_focus_trace);}
  if(phase==3){
   /* Revisit the starting position to reject illumination/time drift. */
   baseline=score;
   /* Zero original detail is a valid blur baseline. A positive winner must
    * still pass the separate fresh-frame remeasurement below. */
   if(best==original||best_quality<=baseline+baseline*12u/100u){best=original;best_quality=baseline;accepted=0;finish_scan(now);return;}
   phase=4;if(move_lens(best,now)){state=0;pending=0;return;}return;
  }
  if(phase==4){
   if(score>baseline+baseline*12u/100u){best_quality=score;accepted=1;finish_scan(now);return;}
   best=original;best_quality=baseline;accepted=0;
   if(move_lens(original,now)){state=0;pending=0;return;}state=5;return;
  }
  if(score>best_quality){best_quality=score;best=pos;}
  index_++;
  unsigned next=next_search_position();
  if(next==1024u){phase=3;if(move_lens(original,now)){state=0;pending=0;return;}return;}
  if(move_lens(next,now)){state=0;pending=0;board_focus_diag[8]++;}return;
 }
 if(state==5 && f[2]==8&&!m[4]){settle_sequence=frame_seq;settle_after=now+70000u;state=6;measure_count=0;measure_sum=0;return;}
 if(state==6&&fresh&&frame_stamp>=settle_after&&scene_stable>=2&&frame_seq-settle_sequence>=2&&frame_seq!=measure_sequence){
  measure_sequence=frame_seq;measure_sum+=quality;
  if(++measure_count>=2){best_quality=(unsigned)(measure_sum/measure_count);finish_scan(now);}
 }
}
