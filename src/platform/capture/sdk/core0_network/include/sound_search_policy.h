#ifndef SOUND_SEARCH_POLICY_H
#define SOUND_SEARCH_POLICY_H
/* The inference engine is shared. During a sound search, interleave ready
 * audio jobs and independent visual jobs. Without audio, vision continues. */
static inline unsigned sound_search_mode(unsigned requested,unsigned visible,
        unsigned seeking,unsigned audio_ready,unsigned last_audio) {
    if(requested!=2)return requested;
    if(visible)return 1;
    (void)seeking; /* Listening/visual search must not depend on servo enable. */
    return audio_ready && !last_audio?0u:1u;
}
static inline unsigned sound_search_audio_blocked(unsigned requested,
        unsigned active,unsigned seeking) {
    return requested==1 || (active==1 && !(requested==2 && seeking));
}
#endif
