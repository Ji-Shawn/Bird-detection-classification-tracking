"""M40 exact NCC address reuse and cooperative scoring time budget.

The 200 us value is a cooperative target, checked after eight complete candidate
scores; one group can overshoot. Frame identity, all search hypotheses, thresholds
and final NCC arithmetic remain unchanged. Native fixtures without a registered
clock retain the prior 64-candidate bound. The production fusion init explicitly
registers the same monotonic microsecond clock used by network scheduling.
"""
MARK='/* M40 bounded NCC scoring with exact sample offsets. */\n'
OLD_DECL='static int16_t motion_sample_x[3][GRID*GRID],motion_sample_y[3][GRID*GRID];'
NEW_DECL=OLD_DECL+'''
static int16_t motion_sample_offset[3][GRID*GRID];
static uint32_t (*tracker_work_clock)(void);
#define TRACKER_SCORE_BUDGET_US 200u
#define TRACKER_SCORE_CLOCK_GROUP 8u
/* Read-only debugger diagnostics: slices, candidates, total scoring us,
 * maximum scoring us, budget yields, candidate-cap yields, clock present. */
volatile uint32_t visual_tracker_cpu_profile[8];
void visual_tracker_set_work_clock(uint32_t (*clock_us)(void)) {
    tracker_work_clock=clock_us;
    memset((void *)visual_tracker_cpu_profile,0,sizeof visual_tracker_cpu_profile);
    visual_tracker_cpu_profile[6]=clock_us!=0;
}'''
OLD_SAMPLE='motion_sample_x[s][i]=(int16_t)x;motion_sample_y[s][i]=(int16_t)y;'
NEW_SAMPLE=OLD_SAMPLE+'\n            motion_sample_offset[s][i]=(int16_t)(y*(int)WIDTH+x);'
OLD_DOT='''    uint32_t sum=0,square=0,dot=0;
    for(unsigned i=0;i<npoints;i++) {
        unsigned v=f->gray[(cy+motion_sample_y[scale][i])*WIDTH+cx+motion_sample_x[scale][i]];
        sum+=v;square+=v*v;dot+=v*template_pixels[i];
    }'''
NEW_DOT='''    uint32_t sum=0,square=0,dot=0;
    const uint8_t *center=f->gray+cy*(int)WIDTH+cx;
    for(unsigned i=0;i<npoints;i++) {
        unsigned v=center[motion_sample_offset[scale][i]];
        sum+=v;square+=v*v;dot+=v*template_pixels[i];
    }'''
OLD_SLICE='''    for(unsigned k=0;k<SLICE_CANDIDATES && search_cursor<motion_candidates;k++,search_cursor++) {
        int dx,dy;unsigned scale;motion_candidate(search_cursor,&dx,&dy,&scale);
        scores[search_cursor]=motion_correlation(f,dx,dy,scale);
    }
    if(search_cursor<motion_candidates)return;'''
NEW_SLICE='''    uint32_t work_start=tracker_work_clock?tracker_work_clock():0u;
    unsigned scored=0,budget_yield=0;
    while(scored<SLICE_CANDIDATES && search_cursor<motion_candidates) {
        int dx,dy;unsigned scale;motion_candidate(search_cursor,&dx,&dy,&scale);
        scores[search_cursor]=motion_correlation(f,dx,dy,scale);
        search_cursor++;scored++;
        /* Unsigned subtraction preserves the short elapsed interval over
         * the 32-bit microsecond counter wrap. No camera time is synthesized. */
        if(tracker_work_clock && !(scored%TRACKER_SCORE_CLOCK_GROUP) &&
           (uint32_t)(tracker_work_clock()-work_start)>=TRACKER_SCORE_BUDGET_US) {
            budget_yield=search_cursor<motion_candidates;break;
        }
    }
    visual_tracker_cpu_profile[0]++;visual_tracker_cpu_profile[1]+=scored;
    if(tracker_work_clock) {
        uint32_t elapsed=(uint32_t)(tracker_work_clock()-work_start);
        visual_tracker_cpu_profile[2]+=elapsed;
        if(elapsed>visual_tracker_cpu_profile[3])visual_tracker_cpu_profile[3]=elapsed;
    }
    visual_tracker_cpu_profile[4]+=budget_yield;
    visual_tracker_cpu_profile[5]+=scored==SLICE_CANDIDATES && search_cursor<motion_candidates;
    if(search_cursor<motion_candidates)return;'''
INIT='    visual_tracker_init();'
NEW_INIT='''    visual_tracker_init();
    visual_tracker_set_work_clock(platform_time_us);'''
SERVICE_HEADER='''/* M40 production NCC scoring clock; no control or image timestamp change. */
#include <stdint.h>
extern void visual_tracker_set_work_clock(uint32_t (*clock_us)(void));
'''

TRANSFORMS=[(OLD_DECL,NEW_DECL),(OLD_SAMPLE,NEW_SAMPLE),(OLD_DOT,NEW_DOT),(OLD_SLICE,NEW_SLICE)]

def tracker(text):
    for old,new in TRANSFORMS:
        assert text.count(old)==1,old
        text=text.replace(old,new,1)
    return MARK+text

def revert_tracker(text):
    assert text.startswith(MARK)
    text=text[len(MARK):]
    for old,new in reversed(TRANSFORMS):
        assert text.count(new)==1,new
        text=text.replace(new,old,1)
    return text

def apply_service(text):
    assert text.count(INIT)==1
    return SERVICE_HEADER+text.replace(INIT,NEW_INIT,1)

def revert_service(text):
    assert text.startswith(SERVICE_HEADER) and text.count(NEW_INIT)==1
    return text[len(SERVICE_HEADER):].replace(NEW_INIT,INIT,1)
