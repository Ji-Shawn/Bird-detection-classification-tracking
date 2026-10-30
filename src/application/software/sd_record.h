#ifndef M48_SD_RECORD_H
#define M48_SD_RECORD_H
#include <stdint.h>
#include <stddef.h>
#define SD_RECORD_MAGIC 0x53443438u
#define SD_RECORD_SHARED_ADDR 0x3003F200u
#define SD_RECORD_PAYLOAD_ADDR 0x37000000u
#define SD_RECORD_SLOT_BYTES 0x100000u
#define SD_RECORD_WIDTH 640u
#define SD_RECORD_HEIGHT 360u
#define SD_RECORD_PIXELS (SD_RECORD_WIDTH*SD_RECORD_HEIGHT)
#define SD_RECORD_BMP_BYTES (54u+SD_RECORD_PIXELS*3u)
#define SD_RECORD_WORDS 12u
enum { SD_SLOT_FREE, SD_SLOT_FILL, SD_SLOT_READY, SD_SLOT_READ };
enum { SD_WRITER_WAIT, SD_WRITER_MOUNT, SD_WRITER_ROOT, SD_WRITER_SESSION,
       SD_WRITER_IDLE, SD_WRITER_OPEN, SD_WRITER_WRITE, SD_WRITER_CLOSE,
       SD_WRITER_RENAME, SD_WRITER_ERROR };
typedef struct __attribute__((aligned(64))) {
    volatile uint32_t state;
    uint32_t boot, sequence, bytes;
    uint64_t captured_us;
    char ebird_code[12];
    uint32_t target_identity;
    uint64_t classified_us;
    uint32_t reserved[4];
} sd_record_slot;
typedef struct __attribute__((aligned(64))) {
    volatile uint32_t magic, boot, produced, dropped, active;
    uint32_t reserved[11];
} sd_record_producer;
typedef struct __attribute__((aligned(64))) {
    volatile uint32_t boot, state, saved, error, bytes, last_sequence, max_io_us, yields;
    uint32_t reserved[8];
} sd_record_consumer;
typedef struct __attribute__((aligned(64))) {
    sd_record_producer producer;
    sd_record_consumer consumer;
    sd_record_slot slot[2];
} sd_record_shared;
_Static_assert(sizeof(sd_record_slot)==64,"SD descriptor cache line");
_Static_assert(offsetof(sd_record_slot,ebird_code)==24,"SD label uses reserved descriptor bytes");
_Static_assert(offsetof(sd_record_slot,target_identity)==36,"SD target identity offset");
_Static_assert(offsetof(sd_record_slot,classified_us)==40,"SD classification timestamp offset");
_Static_assert(sizeof(sd_record_shared)==256,"SD mailbox footprint");
_Static_assert(SD_RECORD_BMP_BYTES<SD_RECORD_SLOT_BYTES,"SD payload bounds");
#ifdef SD_RECORD_HOST
extern sd_record_shared sd_record_host_shared;
extern uint8_t sd_record_host_payload[2][SD_RECORD_SLOT_BYTES];
static inline volatile sd_record_shared *sd_record_mailbox(void){return &sd_record_host_shared;}
static inline uint8_t *sd_record_payload(unsigned slot){return sd_record_host_payload[slot];}
void sd_record_flush(const void *p,uint32_t n);
void sd_record_invalidate(const void *p,uint32_t n);
#else
#include "xil_cache.h"
static inline volatile sd_record_shared *sd_record_mailbox(void){return (volatile sd_record_shared *)(uintptr_t)SD_RECORD_SHARED_ADDR;}
static inline uint8_t *sd_record_payload(unsigned slot){return (uint8_t *)(uintptr_t)(SD_RECORD_PAYLOAD_ADDR+slot*SD_RECORD_SLOT_BYTES);}
static inline void sd_record_flush(const void *p,uint32_t n){Xil_DCacheFlushRange((UINTPTR)p,n);}
static inline void sd_record_invalidate(const void *p,uint32_t n){Xil_DCacheInvalidateRange((UINTPTR)p,n);}
#endif
static inline void sd_record_barrier(void){
#if defined(__arm__)
    __asm__ volatile("dmb sy" ::: "memory");
#else
    __sync_synchronize();
#endif
}
void sd_record_init(uint32_t boot_id);
const char *sd_record_species_code(unsigned species);
void sd_record_label(const char *ebird_code,uint32_t identity,uint64_t classified_us,uint64_t now);
void sd_record_target(unsigned formal,uint64_t now);
void sd_record_frame_begin(uint32_t sequence,uint64_t captured,uint64_t now);
void sd_record_frame_chunk(const void *chunk,uint32_t offset,uint32_t bytes);
void sd_record_frame_end(void);
void sd_record_frame_abort(void);
/* magic, version, flags, fps*1000, tail_ms, queued_total, saved, dropped,
 * queue_depth, FatFs_error, saved_bytes_low32, worst_disk_call_us.
 * flags: 1 enabled, 2 capture active, 4 card ready, 8 writing, 16 fault. */
void sd_record_status(uint32_t words[SD_RECORD_WORDS]);
#endif
