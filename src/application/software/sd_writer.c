/* M51: species/day archives. Core1 alone owns FatFs and the SD controller.
 * Each poll performs one regular filesystem operation; directory scans advance
 * one entry per poll, while the unchanged disk layer yields to audio.
 */
#include "sd_writer.h"
#include "sd_record.h"
#include "sd_disk.h"
#include "sd_vendor/ff.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>
static FATFS filesystem;
static FIL image;
static DIR listing;
static FILINFO entry;
static uint32_t boot,image_id,offset;
static int slot=-1;
static unsigned in_poll,opened,listing_open,phase,date_bad;
static char date[11],date_input[64],directory[64],pending[96],finished[96];
static char cached_code[12];
enum { DATE_OPEN,DATE_READ,DATE_CLOSE,MAKE_DIRECTORY,OPEN_DIRECTORY,
       READ_DIRECTORY,CLOSE_DIRECTORY,CHECK_FINAL,OPEN_IMAGE };
static volatile sd_record_consumer *status(void){return &sd_record_mailbox()->consumer;}
static void error(uint32_t result){
    status()->error=result;status()->state=SD_WRITER_ERROR;
    if(opened){(void)f_close(&image);opened=0;}
    if(listing_open){(void)f_closedir(&listing);listing_open=0;}
    if(slot>=0){sd_record_barrier();sd_record_mailbox()->slot[slot].state=SD_SLOT_FREE;slot=-1;}
}
static unsigned valid_date(const char *text,unsigned size){
    unsigned at=0;
    if(size>=3 && (uint8_t)text[0]==0xef && (uint8_t)text[1]==0xbb && (uint8_t)text[2]==0xbf)at=3;
    if(size-at<10 || text[at+4]!='.' || text[at+7]!='.')return 0;
    for(unsigned i=0;i<10;i++)if(i!=4 && i!=7 && (text[at+i]<'0' || text[at+i]>'9'))return 0;
    unsigned year=(unsigned)(text[at]-'0')*1000u+(unsigned)(text[at+1]-'0')*100u+
                  (unsigned)(text[at+2]-'0')*10u+(unsigned)(text[at+3]-'0');
    unsigned month=(unsigned)(text[at+5]-'0')*10u+(unsigned)(text[at+6]-'0');
    unsigned day=(unsigned)(text[at+8]-'0')*10u+(unsigned)(text[at+9]-'0');
    static const uint8_t days[]={31,28,31,30,31,30,31,31,30,31,30,31};
    if(year<1980 || year>2107 || !month || month>12 || !day)return 0;
    unsigned limit=days[month-1]+(month==2 && (!(year%400) || (!(year%4) && year%100)));
    if(day>limit)return 0;
    for(unsigned i=at+10;i<size;i++)if(text[i]!=' ' && text[i]!='\t' && text[i]!='\r' && text[i]!='\n')return 0;
    memcpy(date,text+at,10);date[10]=0;return 1;
}
static unsigned valid_code(const volatile char *code){
    for(unsigned i=0;i<12;i++){
        unsigned c=(unsigned char)code[i];
        if(!c)return i!=0;
        if(!((c>='a' && c<='z') || (c>='0' && c<='9')))return 0;
    }
    return 0;
}
/* Existing reference JPG/PNG images and interrupted TMP files reserve numbers
 * alongside new BMP files, so copied archives keep one capture sequence. */
static unsigned number(const char *name,uint32_t *value){
    const char *p=name;uint32_t n=0;unsigned overflow=0;
    if(*p<'0' || *p>'9')return 0;
    do{unsigned digit=(unsigned)(*p-'0');
        if(n>(UINT32_MAX-digit)/10u)overflow=1;
        else if(!overflow)n=n*10u+digit;
        ++p;
    }while(*p>='0' && *p<='9');
    if(*p++!='.')return 0;
    size_t length=strlen(p);if(length!=3 && length!=4)return 0;
    unsigned a=(unsigned char)p[0]|32u,b=(unsigned char)p[1]|32u,c=(unsigned char)p[2]|32u;
    unsigned known=length==3 && ((a=='b' && b=='m' && c=='p') || (a=='t' && b=='m' && c=='p') ||
                   (a=='j' && b=='p' && c=='g') || (a=='p' && b=='n' && c=='g'));
    if(length==4)known=a=='j' && b=='p' && c=='e' && (((unsigned char)p[3]|32u)=='g');
    if(!known)return 0;
    *value=n;return overflow?2u:1u;
}
static unsigned next_name(unsigned include_pending){
    if(image_id==UINT32_MAX){error(SD_ARCHIVE_NUMBER_FULL);return 0;}
    ++image_id;
    if(include_pending)snprintf(pending,sizeof pending,"%s/%lu.tmp",directory,(unsigned long)image_id);
    snprintf(finished,sizeof finished,"%s/%lu.bmp",directory,(unsigned long)image_id);
    return 1;
}
void sd_writer_init(uint32_t boot_id,void (*audio_yield)(void *),void *context){
    boot=boot_id;image_id=offset=0;slot=-1;in_poll=opened=listing_open=0;phase=DATE_OPEN;date_bad=0;
    memset(date,0,sizeof date);memset(cached_code,0,sizeof cached_code);
    memset(directory,0,sizeof directory);memset(pending,0,sizeof pending);memset(finished,0,sizeof finished);
    sd_disk_set_yield(audio_yield,context);
    memset((void *)status(),0,sizeof(sd_record_consumer));status()->boot=boot;
    status()->state=SD_WRITER_WAIT;
}
void sd_writer_poll(void){
    volatile sd_record_shared *m=sd_record_mailbox();FRESULT r=FR_OK;UINT transferred=0;
    if(in_poll)return;
    in_poll=1;
    if(m->producer.magic!=SD_RECORD_MAGIC || m->producer.boot!=boot)goto done;
    switch(status()->state){
    case SD_WRITER_WAIT: status()->state=SD_WRITER_MOUNT;break;
    case SD_WRITER_MOUNT:
        r=f_mount(&filesystem,"0:",1);if(r!=FR_OK){error(r);break;}
        /* Only FAT16/FAT32; never format or reinterpret failed reads. */
        if(filesystem.fs_type!=FS_FAT32 && filesystem.fs_type!=FS_FAT16){error(FR_NO_FILESYSTEM);break;}
        status()->state=SD_WRITER_ROOT;break;
    case SD_WRITER_ROOT:
        r=f_mkdir("0:/bird_class");if(r!=FR_OK && r!=FR_EXIST){error(r);break;}
        phase=DATE_OPEN;status()->state=SD_WRITER_SESSION;break;
    case SD_WRITER_SESSION:
        if(phase==DATE_OPEN){
            r=f_open(&image,"0:/bird_class/DATE.TXT",FA_READ);
            if(r!=FR_OK){error(r==FR_NO_FILE || r==FR_NO_PATH?SD_ARCHIVE_DATE_MISSING:(uint32_t)r);break;}
            opened=1;phase=DATE_READ;
        }else if(phase==DATE_READ){
            /* Read a bounded settings file, never compile-time/RTC guesses. */
            if(f_size(&image)>=sizeof date_input){date_bad=1;phase=DATE_CLOSE;break;}
            r=f_read(&image,date_input,sizeof date_input-1u,&transferred);
            if(r!=FR_OK){error(r);break;}
            date_bad=transferred!=f_size(&image) || !valid_date(date_input,transferred);phase=DATE_CLOSE;
        }else{
            r=f_close(&image);opened=0;if(r!=FR_OK){error(r);break;}
            if(date_bad){error(SD_ARCHIVE_DATE_INVALID);break;}status()->state=SD_WRITER_IDLE;
        }
        break;
    case SD_WRITER_IDLE:{
        int oldest=-1;
        for(unsigned i=0;i<2;i++)if(m->slot[i].state==SD_SLOT_READY){
            sd_record_barrier();
            if(m->slot[i].boot!=boot || m->slot[i].bytes!=SD_RECORD_BMP_BYTES){m->slot[i].state=SD_SLOT_FREE;continue;}
            if(oldest<0 || m->slot[i].captured_us<m->slot[oldest].captured_us)oldest=(int)i;
        }
        if(oldest>=0){
            slot=oldest;m->slot[slot].state=SD_SLOT_READ;sd_record_barrier();
            if(!valid_code(m->slot[slot].ebird_code)){error(SD_ARCHIVE_CODE_INVALID);break;}
            sd_record_invalidate(sd_record_payload((unsigned)slot),SD_RECORD_BMP_BYTES);
            offset=0;
            if(strcmp(cached_code,(const char *)m->slot[slot].ebird_code)){
                memcpy(cached_code,(const void *)m->slot[slot].ebird_code,sizeof cached_code);
                snprintf(directory,sizeof directory,"0:/bird_class/%s_%s",cached_code,date);
                image_id=0;phase=MAKE_DIRECTORY;
            }else{if(!next_name(1))break;phase=CHECK_FINAL;}
            status()->state=SD_WRITER_OPEN;
        }
        break;}
    case SD_WRITER_OPEN:
        switch(phase){
        case MAKE_DIRECTORY:
            r=f_mkdir(directory);if(r!=FR_OK && r!=FR_EXIST){error(r);break;}phase=OPEN_DIRECTORY;break;
        case OPEN_DIRECTORY:
            r=f_opendir(&listing,directory);if(r!=FR_OK){error(r);break;}listing_open=1;phase=READ_DIRECTORY;break;
        case READ_DIRECTORY:{
            r=f_readdir(&listing,&entry);if(r!=FR_OK){error(r);break;}
            if(!entry.fname[0]){phase=CLOSE_DIRECTORY;break;}
            /* Numeric directories reserve names too; unrelated entries stay. */
            uint32_t value=0;unsigned kind=number(entry.fname,&value);
            if(kind==2){error(SD_ARCHIVE_NUMBER_FULL);break;}
            if(kind && value>image_id)image_id=value;
            break;}
        case CLOSE_DIRECTORY:
            r=f_closedir(&listing);listing_open=0;if(r!=FR_OK){error(r);break;}
            if(!next_name(1))break;
            phase=CHECK_FINAL;break;
        case CHECK_FINAL:
            r=f_stat(finished,&entry);
            if(r==FR_OK){(void)next_name(1);break;}
            if(r!=FR_NO_FILE){error(r);break;}phase=OPEN_IMAGE;break;
        case OPEN_IMAGE:
            r=f_open(&image,pending,FA_WRITE|FA_CREATE_NEW);
            if(r==FR_EXIST){if(next_name(1))phase=CHECK_FINAL;break;}
            if(r!=FR_OK){error(r);break;}opened=1;status()->state=SD_WRITER_WRITE;break;
        default:error(FR_INT_ERR);break;
        }
        break;
    case SD_WRITER_WRITE:{
        unsigned n=SD_RECORD_BMP_BYTES-offset;if(n>4096)n=4096;
        r=f_write(&image,sd_record_payload((unsigned)slot)+offset,n,&transferred);
        if(r!=FR_OK || transferred!=n){error(r==FR_OK?FR_DENIED:(uint32_t)r);break;}
        offset+=transferred;if(offset==SD_RECORD_BMP_BYTES)status()->state=SD_WRITER_CLOSE;break;}
    case SD_WRITER_CLOSE:
        r=f_close(&image);opened=0;if(r!=FR_OK){error(r);break;}
        status()->state=SD_WRITER_RENAME;break;
    case SD_WRITER_RENAME:
        r=f_rename(pending,finished);
        if(r==FR_EXIST){(void)next_name(0);break;}
        if(r!=FR_OK){error(r);break;}
        status()->saved++;status()->bytes+=SD_RECORD_BMP_BYTES;status()->last_sequence=m->slot[slot].sequence;
        sd_record_barrier();m->slot[slot].state=SD_SLOT_FREE;slot=-1;status()->state=SD_WRITER_IDLE;break;
    default:break;
    }
done:
    status()->max_io_us=sd_disk_max_call_us();status()->yields=sd_disk_yield_count();in_poll=0;
}
