#ifndef SSD_FAST_H
#define SSD_FAST_H
#include <stdint.h>
/* Display-only candidate: no motor, focus, audio or detector-valid writes. */
void ssd_fast_init(uint32_t boot);
void ssd_fast_reset(void);
void ssd_fast_selection(unsigned reason,float score,const float box[4],
                        uint32_t sequence,uint64_t captured,uint64_t now);
void ssd_fast_poll(uint64_t now);
void ssd_fast_send(uint64_t now);
void ssd_fast_hold_scan(uint64_t now);
int ssd_fast_view(uint64_t now,float box[4],float *score);
/* Read-only bridge available only after the selector accepted two independent
 * SSD observations. Both the SSD-capture checkpoint and current position must
 * have completed unique candidate NCC matches. Caller still validates current
 * history/appearance and creates a formal template before any motor use. */
int ssd_fast_handoff(float score,const float confirmed_box[4],uint32_t sequence,
                      uint64_t captured,uint64_t now,float current_box[4],
                      uint32_t *current_sequence,uint64_t *current_captured);
int ssd_fast_class_reuse(uint32_t sequence,uint64_t captured,unsigned policy,
                         uint64_t now,int8_t logits[60],int32_t roi[4],uint32_t *applied);
void ssd_fast_class_store(uint32_t sequence,uint64_t captured,unsigned policy,
                          uint64_t now,const int8_t logits[60],float confidence,const int32_t roi[4],unsigned applied);
void ssd_fast_class_report(uint32_t sequence,uint64_t captured,int reused,uint64_t now);
/* Passive SD metadata only. Freeze identity after SSD selection, then publish
 * the actual image classifier top1 after its original current-job checks.
 * Reused logits keep their real classification completion time. */
uint32_t ssd_fast_archive_identity(uint32_t sequence,uint64_t captured,unsigned policy);
void ssd_fast_archive_store(uint32_t identity,uint32_t sequence,uint64_t captured,
                            unsigned policy,uint64_t now,unsigned species,int reused);
int ssd_fast_archive_snapshot(uint64_t now,uint32_t *species,uint32_t *identity,
                              uint64_t *classified_us);
/* Read-only access to already completed 160x90 tracker history. */
const uint8_t *ssd_history_exact(uint32_t sequence,uint64_t timestamp);
const uint8_t *ssd_history_next(uint64_t after,uint32_t *sequence,uint64_t *timestamp);
#endif
