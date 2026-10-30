#ifndef AV_RESPONSIVENESS_H
#define AV_RESPONSIVENESS_H
#include <stdint.h>
/* Visual presence includes only the tracker's bounded reacquisition grace. */
static inline unsigned response_audio_blocked(unsigned mode,unsigned visible) {
    return mode==1 || (mode==2 && visible);
}
static inline unsigned response_discard_audio(unsigned mode,unsigned frozen,
        unsigned ready,unsigned visible,uint64_t captured,uint64_t now) {
    return mode==2 && !frozen && ready==2 &&
        (visible || now<captured || now-captured>2000000u);
}
static inline unsigned response_audio_only(unsigned mode,unsigned frozen) {
    return mode==2 && !frozen;
}
static inline unsigned response_confirm_first(unsigned mode,unsigned active,
        unsigned pending,unsigned retried) {
    return mode==2 && active==0 && pending && !retried;
}
#endif
