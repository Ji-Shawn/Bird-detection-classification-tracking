#ifndef SOUND_ROUND_POLICY_H
#define SOUND_ROUND_POLICY_H
#include <stdint.h>
#include "av_shared.h"

#define SOUND_ROUND_CAPTURE_SAMPLES 96000u /* 3 s at 32 kHz */
#define SOUND_ROUND_MODEL_SAMPLES 160000u /* frozen five-second model ABI */
#define SOUND_ROUND_CAPTURE_US 3000000u
#define SOUND_ROUND_HOP_US 15000u /* completion timestamp of a 480-sample block */
#define SOUND_ROUND_RESULT_GAP_US 3000000u
#define SOUND_ROUND_RESET_GAP_US 8000000u
#define SOUND_ROUND_PAUSE_US 5000000u
/* The two unused cache lines between live DOA (+0x40) and clock diagnostics
 * (+0x100) are reserved here. Core0 is the only writer; Core1 only reads.
 * Both CPUs map the containing shared megabyte as noncacheable. */
#define SOUND_ROUND_CONTROL_ADDR 0x30070080u
#define SOUND_ROUND_CONTROL_MAGIC 0x53524431u
/* The next unused cache line is Core1's single-writer adoption receipt. */
#define SOUND_ROUND_RECEIPT_ADDR 0x300700C0u
#define SOUND_ROUND_RECEIPT_MAGIC 0x53524132u
typedef struct {
    uint32_t revision,capture_ms,min_gap_ms,reset_gap_ms,pause_ms;
} sound_round_settings;
#define SOUND_ROUND_SETTINGS_DEFAULTS {1u,3000u,3000u,8000u,5000u}
typedef struct {
    volatile uint32_t generation;
    uint32_t magic;
    uint64_t resume_after;
    uint64_t adopted_after;
    sound_round_settings settings;
    uint32_t reserved[5];
} sound_round_control;
_Static_assert(sizeof(sound_round_control)==64u,"sound round control cache line");
typedef struct {
    volatile uint32_t generation;
    uint32_t magic,revision,boot_id,reserved[12];
} sound_round_receipt;
_Static_assert(sizeof(sound_round_receipt)==64u,"sound round adoption cache line");

static inline uint64_t sound_round_add(uint64_t now,uint64_t delta) {
    return UINT64_MAX-now<delta?UINT64_MAX:now+delta;
}
static inline void sound_round_publish_config(volatile sound_round_control *p,
        uint64_t resume,uint64_t adopted,const sound_round_settings *settings) {
    uint32_t version=p->generation;
    p->generation=version|1u;av_memory_barrier();
    p->magic=SOUND_ROUND_CONTROL_MAGIC;p->resume_after=resume;p->adopted_after=adopted;
    p->settings=*settings;
    av_memory_barrier();p->generation=(version|1u)+1u;
}
static inline int sound_round_snapshot_config(const volatile sound_round_control *p,
        uint32_t *version,uint64_t *resume,uint64_t *adopted,sound_round_settings *settings) {
    uint32_t before=p->generation;av_memory_barrier();
    uint32_t magic=p->magic;uint64_t until=p->resume_after;
    uint64_t after=p->adopted_after;sound_round_settings current=p->settings;
    av_memory_barrier();
    if((before&1u) || before!=p->generation)return 0;
    const sound_round_settings defaults=SOUND_ROUND_SETTINGS_DEFAULTS;
    *version=before;*resume=magic==SOUND_ROUND_CONTROL_MAGIC?until:0;
    *adopted=magic==SOUND_ROUND_CONTROL_MAGIC?after:0;
    *settings=magic==SOUND_ROUND_CONTROL_MAGIC?current:defaults;
    return 1;
}
/* Compatibility operations change only the round deadline, preserving a
 * previously adopted timing revision. A zeroed mailbox starts at M45 defaults. */
static inline void sound_round_publish(volatile sound_round_control *p,uint64_t resume) {
    uint32_t version;uint64_t old,after;sound_round_settings settings;
    if(!sound_round_snapshot_config(p,&version,&old,&after,&settings)) {
        /* Core0 owns every field here. It can complete its own interrupted
         * publication; readers must still reject that odd generation. */
        const sound_round_settings defaults=SOUND_ROUND_SETTINGS_DEFAULTS;
        settings=p->magic==SOUND_ROUND_CONTROL_MAGIC?p->settings:defaults;
        after=p->magic==SOUND_ROUND_CONTROL_MAGIC?p->adopted_after:0;
    }
    sound_round_publish_config(p,resume,after,&settings);
}
static inline int sound_round_snapshot(const volatile sound_round_control *p,
                                      uint32_t *version,uint64_t *resume) {
    uint64_t after;sound_round_settings settings;
    return sound_round_snapshot_config(p,version,resume,&after,&settings);
}
static inline void sound_round_receipt_publish_boot(volatile sound_round_receipt *p,
        uint32_t revision,uint32_t boot_id) {
    uint32_t generation=p->generation;
    p->generation=generation|1u;av_memory_barrier();
    p->magic=SOUND_ROUND_RECEIPT_MAGIC;p->revision=revision;p->boot_id=boot_id;
    av_memory_barrier();p->generation=(generation|1u)+1u;
}
static inline void sound_round_receipt_publish(volatile sound_round_receipt *p,uint32_t revision) {
    sound_round_receipt_publish_boot(p,revision,0);
}
static inline uint32_t sound_round_receipt_read(const volatile sound_round_receipt *p) {
    uint32_t before=p->generation;av_memory_barrier();
    uint32_t magic=p->magic,revision=p->revision;av_memory_barrier();
    return !(before&1u) && before==p->generation && magic==SOUND_ROUND_RECEIPT_MAGIC?revision:0;
}
static inline uint32_t sound_round_receipt_read_boot(const volatile sound_round_receipt *p,
        uint32_t boot_id) {
    uint32_t before=p->generation;av_memory_barrier();
    uint32_t magic=p->magic,revision=p->revision,boot=p->boot_id;av_memory_barrier();
    return !(before&1u) && before==p->generation && magic==SOUND_ROUND_RECEIPT_MAGIC &&
        boot_id && boot==boot_id?revision:0;
}
typedef struct {
    uint32_t version,initialized,revision,capture_samples;
    uint64_t resume,adopted;
} sound_round_reader;
/* A new generation invalidates even a partially collected old window.
 * A torn control read fails closed for classification, never for live DOA. */
static inline int sound_round_collect(sound_round_reader *r,
        const volatile sound_round_control *p,uint64_t captured,unsigned *reset) {
    uint32_t version;uint64_t resume,adopted;sound_round_settings settings;*reset=0;
    if(!sound_round_snapshot_config(p,&version,&resume,&adopted,&settings)){*reset=1;return 0;}
    if(!r->initialized || version!=r->version) {
        r->initialized=1;r->version=version;r->resume=resume;r->adopted=adopted;
        r->revision=settings.revision;r->capture_samples=settings.capture_ms*32u;*reset=1;
    }
    /* Do not retain the first block whose completion crosses the deadline:
     * it can contain up to 15 ms captured during the cooldown. */
    uint64_t after=r->resume>r->adopted?r->resume:r->adopted;
    return captured && (!after || captured>=sound_round_add(after,SOUND_ROUND_HOP_US));
}
/* All real PCM must have been collected after both adoption and cooldown. */
static inline int sound_round_result_fresh_config(uint64_t captured,uint64_t now,
        uint64_t resume,uint64_t adopted,uint32_t capture_ms) {
    uint64_t after=resume>adopted?resume:adopted;
    return captured && captured<=now && (!after ||
        (now>=after && captured>=sound_round_add(after,(uint64_t)capture_ms*1000u)));
}
/* Default wrapper retained for existing callers and historical native tests. */
static inline int sound_round_result_fresh(uint64_t captured,uint64_t now,uint64_t resume) {
    return sound_round_result_fresh_config(captured,now,resume,0,3000u);
}
#endif
