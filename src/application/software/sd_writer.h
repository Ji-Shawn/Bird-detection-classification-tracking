#ifndef M48_SD_WRITER_H
#define M48_SD_WRITER_H
#include <stdint.h>
/* Recorder setup errors are separate from the unchanged FatFs result codes. */
#define SD_ARCHIVE_DATE_MISSING 0x5101u
#define SD_ARCHIVE_DATE_INVALID 0x5102u
#define SD_ARCHIVE_CODE_INVALID 0x5103u
#define SD_ARCHIVE_NUMBER_FULL  0x5104u
void sd_writer_init(uint32_t boot_id,void (*audio_yield)(void *),void *context);
void sd_writer_poll(void);
#endif
