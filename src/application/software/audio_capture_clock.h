#ifndef AUDIO_CAPTURE_CLOCK_H
#define AUDIO_CAPTURE_CLOCK_H
#include <stdint.h>
#include <string.h>

/* Completion callbacks are not sample-clock edges. The unchanged PCM adapter
 * buffers two 480-sample banks; consecutive successfully captured blocks have
 * a 15 ms sample cadence unless its overflow counter or DMA recovery changes.
 * Keep a conservative 30 ms initial age instead of dating queued samples in
 * the future. These are estimated sample times, not hardware sample indices. */
typedef struct {
    uint64_t stamp, completion;
    uint32_t errors, discontinuities, delayed_callbacks;
    unsigned valid, broken;
} audio_capture_clock;

static inline void audio_capture_clock_break(audio_capture_clock *c) {c->broken=1;}

static inline uint64_t audio_capture_clock_stamp(audio_capture_clock *c,
        uint64_t completed, uint32_t errors, unsigned *gap) {
    unsigned reset=c->broken || (c->valid && (errors!=c->errors ||
        completed<=c->completion || completed-c->completion>100000u ||
        (completed>c->stamp && completed-c->stamp>75000u)));
    if(c->valid && completed>c->completion && completed-c->completion>22500u)
        c->delayed_callbacks++;
    uint64_t next=c->stamp+15000u;
    /* Bound long-run nominal-clock drift; do not silently join a clock jump. */
    if(c->valid && next>completed)reset=1;
    *gap=c->valid && reset;
    if(!c->valid || reset)next=completed>30000u?completed-30000u:1u;
    c->stamp=next;c->completion=completed;c->errors=errors;c->valid=1;c->broken=0;
    c->discontinuities+=*gap;
    return next;
}
#endif
