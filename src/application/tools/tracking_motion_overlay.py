"""Bounded motion/scale recovery on the existing authoritative NCC tracker.

Normal measurements retain the original fast path and all acceptance gates.
Expanded search uses a fixed candidate cap, with broad/near size hypotheses.
Every exact score already seen in the current image participates in the final
spatial uniqueness check, including windows that failed before recovery.
"""
MARK = '/* M44 bounded fast motion and scale recovery. */\n'


def apply(text):
    pairs = [
        ('#define GRID 12u', '#define MOTION_SCALES 5u\n#define MOTION_REFINE_SCALES 7u\n#define GRID 12u'),
        ('static float motion_scales[3],motion_outer_second;',
         '''static float motion_scales[MOTION_REFINE_SCALES],motion_outer_second;
static unsigned motion_search_step;
/* Positive score+2 marks a touched center. Only entries touched in the
 * preceding image are cleared, keeping normal-frame bookkeeping bounded. */
static float motion_known[WIDTH*HEIGHT];
static uint16_t motion_known_at[WIDTH*HEIGHT];
static unsigned motion_known_count;
static void motion_known_reset(void) {
    for(unsigned i=0;i<motion_known_count;i++)motion_known[motion_known_at[i]]=0.f;
    motion_known_count=0;
}
static void motion_known_add(int dx,int dy,float score) {
    if(score<=-2.f)return;
    int x=origin_x+dx,y=origin_y+dy;
    if(x<0 || x>=(int)WIDTH || y<0 || y>=(int)HEIGHT)return;
    unsigned at=(unsigned)y*WIDTH+(unsigned)x;
    if(!motion_known[at])motion_known_at[motion_known_count++]=(uint16_t)at;
    if(score+2.f>motion_known[at])motion_known[at]=score+2.f;
}
static float motion_known_second(int dx,int dy) {
    int cx=origin_x+dx,cy=origin_y+dy;float second=-2.f;
    for(unsigned i=0;i<motion_known_count;i++) {
        unsigned at=motion_known_at[i];int x=(int)(at%WIDTH)-cx,y=(int)(at/WIDTH)-cy;
        if(x*x+y*y>=9 && motion_known[at]-2.f>second)second=motion_known[at]-2.f;
    }
    return second;
}'''),
        ('motion_sample_x[3][GRID*GRID],motion_sample_y[3][GRID*GRID]',
         'motion_sample_x[MOTION_REFINE_SCALES][GRID*GRID],motion_sample_y[MOTION_REFINE_SCALES][GRID*GRID]'),
        ('motion_sample_offset[3][GRID*GRID]', 'motion_sample_offset[MOTION_REFINE_SCALES][GRID*GRID]'),
        ('motion_min_x[3],motion_max_x[3],motion_min_y[3],motion_max_y[3]',
         'motion_min_x[MOTION_REFINE_SCALES],motion_max_x[MOTION_REFINE_SCALES],motion_min_y[MOTION_REFINE_SCALES],motion_max_y[MOTION_REFINE_SCALES]'),
        ('motion_centers_x[6],motion_centers_y[6]',
         'motion_centers_x[2*MOTION_REFINE_SCALES],motion_centers_y[2*MOTION_REFINE_SCALES]'),
        ('    acquire_catchup=0;\n    active=processing=misses=0;',
         '    motion_known_reset();\n    acquire_catchup=0;\n    active=processing=misses=0;'),
        ('    if(now<confirmed || (have_frame && now<history[head].timestamp))',
         '''    /* A new complete image can supersede an expired recovery job.
     * Do not spend more slices finishing a frame that can no longer drive. */
    if(processing && search_slot!=head && now>=search_timestamp &&
       now-search_timestamp>VISUAL_SERVO_POSITION_MAX_AGE_US &&
       history[head].valid && now>=history[head].timestamp &&
       now-history[head].timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US)processing=0;
    if(now<confirmed || (have_frame && now<history[head].timestamp))'''),
        ('unsigned fresh_catchup=acquire_catchup && history[head].valid &&',
         '''unsigned fresh_catchup=(acquire_catchup ||
            (now>=earliest && now-earliest>VISUAL_SERVO_POSITION_MAX_AGE_US)) && history[head].valid &&'''),
        ('?1u:hypothesis%3u;', '?1u:hypothesis%(motion_phase==MOTION_REFINE?MOTION_REFINE_SCALES:MOTION_SCALES);'),
        ('else if(motion_phase==MOTION_EXPANDED){*dx=x*3;*dy=y*3;}',
         'else if(motion_phase==MOTION_EXPANDED){*dx=x*(int)motion_search_step;*dy=y*(int)motion_search_step;}'),
        ('?1u:phase==MOTION_REFINE?6u:3u);',
         '?1u:phase==MOTION_REFINE?2u*MOTION_REFINE_SCALES:MOTION_SCALES);'),
        ('        processing=1;search_radius=misses?RECOVERY_RADIUS:RADIUS;',
         '''        motion_known_reset();
        processing=1;search_radius=misses?RECOVERY_RADIUS:RADIUS;'''),
        ('        motion_samples();motion_stage(MOTION_NORMAL,(unsigned)(2*search_radius+1));',
         '''        /* Ten coarse cells in each direction; widening changes spacing,
         * never candidate count. Fine +/-3 covers the maximum six-cell step. */
        float span=fmaxf(fabsf(motion_x*ratio),fabsf(motion_y*ratio))+RADIUS;
        if(earliest-last_processed>=300000u)span=fmaxf(span,60.f);
        else if(earliest-last_processed>=150000u)span=fmaxf(span,50.f);
        motion_search_step=(unsigned)ceilf(fmaxf(5.f,fminf(6.f,span/10.f)));
        motion_samples();motion_stage(MOTION_NORMAL,(unsigned)(2*search_radius+1));'''),
        ('        scores[search_cursor]=motion_correlation(f,dx,dy,scale);',
         '''        scores[search_cursor]=motion_correlation(f,dx,dy,scale);
        motion_known_add(dx,dy,scores[search_cursor]);'''),
        ('    motion_candidate(best,&dx,&dy,&scale);\n    if(motion_phase==MOTION_SCALE)',
         '''    motion_candidate(best,&dx,&dy,&scale);
    /* A new search window must not forget competing exact-image evidence. */
    float known_second=motion_known_second(dx,dy);
    if(known_second>second)second=known_second;
    if(motion_phase==MOTION_SCALE)'''),
        ('motion_stage(MOTION_EXPANDED,25u)', 'motion_stage(MOTION_EXPANDED,21u)'),
        ('        for(unsigned s=0;s<3;s++) {\n            unsigned peak=s*plane;',
         '        for(unsigned s=0;s<MOTION_SCALES;s++) {\n            unsigned peak=s*plane;'),
        ('motion_centers_x[s+3u],&motion_centers_y[s+3u]',
         'motion_centers_x[s+MOTION_REFINE_SCALES],&motion_centers_y[s+MOTION_REFINE_SCALES]'),
        ('        motion_stage(MOTION_REFINE,7u);return;',
         '''        /* Keep all five coarse scales and both their spatial peaks.
         * Fine sizes follow each shrink/grow branch independently: the
         * global coarse winner can be biased by its translation-grid phase.
         * This avoids accumulating 10-percent geometry quantization. */
        motion_scales[5]=motion_scales[0]*.975f;
        motion_scales[6]=motion_scales[2]*1.025f;
        for(unsigned s=5;s<MOTION_REFINE_SCALES;s++) {
            unsigned anchor=s==5?0u:2u;
            motion_centers_x[s]=motion_centers_x[anchor];
            motion_centers_y[s]=motion_centers_y[anchor];
            motion_centers_x[s+MOTION_REFINE_SCALES]=motion_centers_x[anchor+MOTION_REFINE_SCALES];
            motion_centers_y[s+MOTION_REFINE_SCALES]=motion_centers_y[anchor+MOTION_REFINE_SCALES];
        }
        motion_sample_geometry();motion_stage(MOTION_REFINE,7u);return;'''),
        ('(dx<=-36 || dx>=36 || dy<=-36 || dy>=36)',
         '(dx<=-(int)(10u*motion_search_step) || dx>=(int)(10u*motion_search_step) ||\n         dy<=-(int)(10u*motion_search_step) || dy>=(int)(10u*motion_search_step))'),
        ('f->timestamp-stable_last_scale>=200000u', 'f->timestamp-stable_last_scale>=100000u'),
        ('(template_pixels[i]+current+1u)/2u', '(3u*template_pixels[i]+current+2u)/4u'),
        (' * At most one 75-candidate check per 200 ms capture time.',
         ' * At most one 125-candidate check per 100 ms capture time.'),
        ('    motion_x=dx;motion_y=dy;motion_dt=f->timestamp-last_processed;',
         '''    /* A confirmed reversal invalidates the previous constant-velocity
     * direction immediately; let the next frame establish the new velocity. */
    unsigned reversed=(motion_x && dx && ((motion_x<0)!=(dx<0))) ||
                      (motion_y && dy && ((motion_y<0)!=(dy<0)));
    motion_x=reversed?0:dx;motion_y=reversed?0:dy;motion_dt=f->timestamp-last_processed;'''),
        ('for(unsigned s=0;s<3;s++)motion_centers_x[s]=motion_centers_y[s]=0;',
         'for(unsigned s=0;s<MOTION_SCALES;s++)motion_centers_x[s]=motion_centers_y[s]=0;'),
    ]
    for old, new in pairs:
        count = text.count(old)
        # Both failed normal and failed recentered windows use the same retry.
        expected = 2 if old in ('motion_stage(MOTION_EXPANDED,25u)',
                               '(template_pixels[i]+current+1u)/2u') else 1
        assert count == expected, (old, count, expected)
        text = text.replace(old, new)
    start = text.index('static void motion_samples(void) {')
    end = text.index('static float motion_correlation(', start)
    old = text[start:end]
    geometry = old.replace('static void motion_samples(void)', 'static void motion_sample_geometry(void)', 1)
    geometry = geometry.replace('for(unsigned s=0;s<3;s++) {\n        motion_scales[s]=motion_scale*(s==0?.9f:s==1?1.f:1.1f);',
                                'for(unsigned s=0;s<MOTION_REFINE_SCALES;s++) {', 1)
    assert geometry != old and 's<3' not in geometry
    init = '''static void motion_samples(void) {
    static const float ratios[MOTION_SCALES]={.9f,1.f,1.1f,.7f,1.3f};
    for(unsigned s=0;s<MOTION_SCALES;s++)motion_scales[s]=motion_scale*ratios[s];
    motion_scales[5]=motion_scales[6]=motion_scale;
    motion_sample_geometry();
}
'''
    text = text[:start] + geometry + init + text[end:]
    return MARK + text
