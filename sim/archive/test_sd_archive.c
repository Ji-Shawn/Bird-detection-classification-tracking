#include "sd_record.h"
#include "sd_writer.h"
#include "sd_disk.h"
#include "ff.h"
#include "diskio.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
sd_record_shared sd_record_host_shared;
uint8_t sd_record_host_payload[2][SD_RECORD_SLOT_BYTES];
static uint8_t vbr[512];
/* Sparse sector emulator: the REAL Windows card VBR, synthesized matching MBR,
 * pristine FAT32 allocation tables, and normal sector reads/writes. FatFs is
 * the actual vendored implementation, not mocked file API calls. */
#define CACHE 16384u
typedef struct { uint32_t sector;uint8_t data[512]; } sector_entry;
static sector_entry cache[CACHE];
static unsigned writes,reads,yields,fail_write,full,call_max,flush_max,read_mbr,read_vbr,callback_count,fixture_io;
static void (*yield_fn)(void *);static void *yield_arg;
static uint32_t u32(const uint8_t *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
static uint16_t u16(const uint8_t *p){return p[0]|(uint16_t)p[1]<<8;}
static void put32(uint8_t *p,uint32_t v){for(unsigned i=0;i<4;i++)p[i]=(uint8_t)(v>>(8*i));}
static sector_entry *find(uint32_t sector,unsigned make){
    unsigned i=sector%CACHE;
    for(unsigned n=0;n<CACHE;n++,i=(i+1)%CACHE){
        if(cache[i].sector==sector)return &cache[i];
        if(cache[i].sector==0xffffffffu){if(!make)return 0;cache[i].sector=sector;return &cache[i];}}
    assert(0);return 0;
}
static void base_sector(uint32_t sector,uint8_t *out){
    memset(out,0,512);unsigned base=u32(vbr+28),reserved=u16(vbr+14),fat=u32(vbr+36);
    if(sector==0){read_mbr++;out[446+4]=0x0c;put32(out+446+8,base);put32(out+446+12,u32(vbr+32));out[510]=0x55;out[511]=0xaa;}
    else if(sector==base){read_vbr++;memcpy(out,vbr,512);}
    else if(sector==base+u16(vbr+48)){
        put32(out,0x41615252);put32(out+484,0x61417272);put32(out+488,full?0:0xffffffffu);
        put32(out+492,2);put32(out+508,0xaa550000);}
    else if(sector==base+reserved || sector==base+reserved+fat){
        put32(out,0x0ffffff8);put32(out+4,0x0fffffff);put32(out+8,0x0fffffff);}
}
void sd_record_flush(const void *p,uint32_t n){assert(p);assert(n<=24000);if(n>flush_max)flush_max=n;}
void sd_record_invalidate(const void *p,uint32_t n){assert(p);assert(n==SD_RECORD_BMP_BYTES);}
void sd_disk_set_yield(void (*fn)(void *),void *arg){yield_fn=fn;yield_arg=arg;yields=callback_count=0;}
uint32_t sd_disk_max_call_us(void){return call_max;}
uint32_t sd_disk_yield_count(void){return yields;}
static void yield(void){yields++;if(yield_fn)yield_fn(yield_arg);}
DSTATUS disk_initialize(BYTE d){return d?STA_NOINIT:0;}
DSTATUS disk_status(BYTE d){return d?STA_NOINIT:0;}
DRESULT disk_read(BYTE d,BYTE *out,LBA_t sector,UINT n){
    assert(!d && n && n<=8);if(n>call_max)call_max=n;
    for(unsigned j=0;j<n;j++){sector_entry *e=find(sector+j,0);if(e)memcpy(out+j*512,e->data,512);else base_sector(sector+j,out+j*512);reads++;yield();}
    return RES_OK;
}
DRESULT disk_write(BYTE d,const BYTE *in,LBA_t sector,UINT n){
    assert(!d && n && n<=8);if(n>call_max)call_max=n;
    if(fail_write){writes++;return RES_ERROR;}
    for(unsigned j=0;j<n;j++){sector_entry *e=find(sector+j,1);memcpy(e->data,in+j*512,512);writes++;yield();}
    return RES_OK;
}
DRESULT disk_ioctl(BYTE d,BYTE c,void *p){assert(!d);if(c==CTRL_SYNC)return RES_OK;
    if(c==GET_SECTOR_COUNT){*(LBA_t *)p=u32(vbr+28)+u32(vbr+32);return RES_OK;}return RES_PARERR;}
static FATFS setup_fs;
static void audio_yield(void *arg){assert(arg==&callback_count);callback_count++;if(!fixture_io)sd_writer_poll();}
static void polls(unsigned count){while(count--)sd_writer_poll();}
static void idle(void){for(unsigned n=0;n<10000 && sd_record_host_shared.consumer.state!=SD_WRITER_IDLE && sd_record_host_shared.consumer.state!=SD_WRITER_ERROR;n++)sd_writer_poll();assert(sd_record_host_shared.consumer.state==SD_WRITER_IDLE);}
static void ready(unsigned index,unsigned sequence,uint64_t stamp,const char *code,unsigned marker){
    sd_record_slot *s=&sd_record_host_shared.slot[index];assert(s->state==SD_SLOT_FREE);
    memset(s,0,sizeof *s);s->boot=1;s->sequence=sequence;s->captured_us=stamp;s->bytes=SD_RECORD_BMP_BYTES;
    if(strlen(code)<sizeof s->ebird_code)strcpy(s->ebird_code,code);else memcpy(s->ebird_code,code,sizeof s->ebird_code);
    s->target_identity=1;s->classified_us=stamp;
    uint8_t *p=sd_record_host_payload[index];memset(p,marker,SD_RECORD_BMP_BYTES);memset(p,0,54);
    p[0]='B';p[1]='M';put32(p+2,SD_RECORD_BMP_BYTES);put32(p+10,54);put32(p+14,40);put32(p+18,640);put32(p+22,(uint32_t)-360);p[26]=1;p[28]=24;put32(p+34,640u*360u*3u);
    s->state=SD_SLOT_READY;
}
static void start(void){memset(&sd_record_host_shared,0,sizeof sd_record_host_shared);sd_record_host_shared.producer.boot=1;sd_record_host_shared.producer.magic=SD_RECORD_MAGIC;sd_writer_init(1,audio_yield,&callback_count);}
/* Fixture edits occur between writer polls, never recursively inside FatFs. */
static void textfile(const char *path,const char *text){FIL f;UINT wrote;fixture_io=1;assert(f_open(&f,path,FA_WRITE|FA_CREATE_ALWAYS)==FR_OK);assert(f_write(&f,text,(UINT)strlen(text),&wrote)==FR_OK && wrote==strlen(text));assert(f_close(&f)==FR_OK);fixture_io=0;}
static void seed_date(const char *text){assert(f_mount(&setup_fs,"0:",1)==FR_OK);assert(f_mkdir("0:/bird_class")==FR_OK);if(text)textfile("0:/bird_class/DATE.TXT",text);}
static void absent(const char *path){FILINFO f;assert(f_stat(path,&f)==FR_NO_FILE);}
static void check_bmp(const char *path,unsigned marker){
    FIL f;UINT n;uint8_t block[4096];unsigned at=0;assert(f_open(&f,path,FA_READ)==FR_OK);assert(f_size(&f)==SD_RECORD_BMP_BYTES);
    while(at<SD_RECORD_BMP_BYTES){unsigned want=SD_RECORD_BMP_BYTES-at;if(want>sizeof block)want=sizeof block;assert(f_read(&f,block,want,&n)==FR_OK && n==want);for(unsigned i=0;i<n;i++)if(at+i>=54)assert(block[i]==marker);if(at==0)assert(block[0]=='B' && block[1]=='M' && u32(block+18)==640 && u32(block+22)==(uint32_t)-360);at+=n;}
    assert(f_close(&f)==FR_OK);
}
static void save(unsigned sequence,const char *code,unsigned marker){ready(0,sequence,sequence*1000000ull,code,marker);polls(500);assert(sd_record_host_shared.consumer.state==SD_WRITER_IDLE);}
static void expect_error(unsigned code){polls(1000);assert(sd_record_host_shared.consumer.state==SD_WRITER_ERROR);assert(sd_record_host_shared.consumer.error==code);unsigned before=writes;polls(100);assert(writes==before);}
int main(int argc,char **argv){
    assert(argc==3);FILE *f=fopen(argv[1],"rb");assert(f && fread(vbr,1,512,f)==512);fclose(f);
    assert(vbr[510]==0x55 && vbr[511]==0xaa && u16(vbr+11)==512);
    for(unsigned i=0;i<CACHE;i++)cache[i].sector=0xffffffffu;
    const char *mode=argv[2];
    if(!strcmp(mode,"badfs")){vbr[510]=0;start();expect_error(FR_NO_FILESYSTEM);assert(!writes);puts("BAD_FS_NO_WRITE_PASS");return 0;}
    if(!strcmp(mode,"missing")){seed_date(0);start();expect_error(SD_ARCHIVE_DATE_MISSING);puts("DATE_MISSING_NO_PHOTO_PASS");return 0;}
    if(!strncmp(mode,"invalid:",8)){seed_date(mode+8);start();expect_error(SD_ARCHIVE_DATE_INVALID);puts("INVALID_DATE_NO_PHOTO_PASS");return 0;}
    if(!strncmp(mode,"valid:",6) || !strcmp(mode,"validbom")){
        seed_date(!strcmp(mode,"validbom")?"\xef\xbb\xbf" "2026.10.27\r\n":mode+6);
        start();idle();save(1,"comnig1",7);assert(sd_record_host_shared.consumer.saved==1);puts("VALID_DATE_PASS");return 0;}
    seed_date("2026.10.27\r\n");
    if(!strcmp(mode,"resume")){
        assert(f_mkdir("0:/bird_class/comnig1_2026.10.27")==FR_OK);
        textfile("0:/bird_class/comnig1_2026.10.27/1.bmp","old photo");textfile("0:/bird_class/comnig1_2026.10.27/3.tmp","unfinished");
        textfile("0:/bird_class/comnig1_2026.10.27/README.TXT","keep me");
    }
    if(!strcmp(mode,"numbers")){
        assert(f_mkdir("0:/bird_class/comnig1_2026.10.27")==FR_OK);
        textfile("0:/bird_class/comnig1_2026.10.27/9.bmp","9");textfile("0:/bird_class/comnig1_2026.10.27/10.BMP","10");textfile("0:/bird_class/comnig1_2026.10.27/00012.tmp","12");
        textfile("0:/bird_class/comnig1_2026.10.27/21.jpg","21");textfile("0:/bird_class/comnig1_2026.10.27/22.JPEG","22");textfile("0:/bird_class/comnig1_2026.10.27/23.PnG","23");
    }
    if(!strcmp(mode,"many")){
        assert(f_mkdir("0:/bird_class/comnig1_2026.10.27")==FR_OK);
        for(unsigned i=0;i<300;i++){char path[96];snprintf(path,sizeof path,"0:/bird_class/comnig1_2026.10.27/note%u.txt",i);textfile(path,"preserve");}
    }
    if(!strcmp(mode,"max") || !strcmp(mode,"overflow")){
        assert(f_mkdir("0:/bird_class/comnig1_2026.10.27")==FR_OK);
        textfile(!strcmp(mode,"max")?"0:/bird_class/comnig1_2026.10.27/4294967294.tmp":"0:/bird_class/comnig1_2026.10.27/4294967296.bmp","keep");
    }
    if(!strcmp(mode,"full")){full=1;/* Re-mount will reload FSInfo. */
        sector_entry *info=find(u32(vbr+28)+u16(vbr+48),1);base_sector(info->sector,info->data);put32(info->data+488,0);}
    start();idle();assert(read_mbr && read_vbr);
    if(!strcmp(mode,"many")){
        ready(0,1,1000000,"comnig1",17);unsigned steps=0;
        while(sd_record_host_shared.consumer.state!=SD_WRITER_WRITE && sd_record_host_shared.consumer.state!=SD_WRITER_ERROR && steps<1000){sd_writer_poll();steps++;}
        assert(steps>=300 && sd_record_host_shared.consumer.state==SD_WRITER_WRITE);
        polls(500);check_bmp("0:/bird_class/comnig1_2026.10.27/1.bmp",17);puts("LARGE_DIRECTORY_COOPERATIVE_SCAN_PASS");return 0;
    }
    if(!strcmp(mode,"collisions")){
        save(1,"comnig1",1);
        textfile("0:/bird_class/comnig1_2026.10.27/2.bmp","preserve final");textfile("0:/bird_class/comnig1_2026.10.27/3.tmp","preserve temporary");
        save(2,"comnig1",4);check_bmp("0:/bird_class/comnig1_2026.10.27/4.bmp",4);
        ready(0,3,3000000,"comnig1",5);
        for(unsigned i=0;i<1000 && sd_record_host_shared.consumer.state!=SD_WRITER_RENAME;i++)sd_writer_poll();
        assert(sd_record_host_shared.consumer.state==SD_WRITER_RENAME);
        textfile("0:/bird_class/comnig1_2026.10.27/5.bmp","rename collision");
        polls(100);check_bmp("0:/bird_class/comnig1_2026.10.27/6.bmp",5);
        FIL preserved;UINT read;char text[20]={0};assert(f_open(&preserved,"0:/bird_class/comnig1_2026.10.27/5.bmp",FA_READ)==FR_OK);
        assert(f_read(&preserved,text,16,&read)==FR_OK && !memcmp(text,"rename collision",16));assert(f_close(&preserved)==FR_OK);
        puts("OPEN_AND_RENAME_COLLISION_NO_OVERWRITE_PASS");return 0;
    }
    if(!strcmp(mode,"invalidcode")){ready(0,1,1000000,"../../x",1);expect_error(SD_ARCHIVE_CODE_INVALID);assert(!sd_record_host_shared.consumer.saved);puts("INVALID_CODE_NO_PATH_ESCAPE_PASS");return 0;}
    if(!strcmp(mode,"nonterminated")){ready(0,1,1000000,"abcdefghijkl",1);expect_error(SD_ARCHIVE_CODE_INVALID);puts("NONTERMINATED_CODE_REJECT_PASS");return 0;}
    if(!strcmp(mode,"full")){ready(0,1,1000000,"comnig1",1);expect_error(FR_DENIED);puts("CARD_FULL_STOPS_PASS");return 0;}
    if(!strcmp(mode,"error")){ready(0,1,1000000,"comnig1",1);fail_write=1;expect_error(FR_DISK_ERR);puts("DISK_ERROR_STOPS_PASS");return 0;}
    if(!strcmp(mode,"overflow")){ready(0,1,1000000,"comnig1",1);expect_error(SD_ARCHIVE_NUMBER_FULL);puts("OVERFLOW_EXISTING_NUMBER_REJECT_PASS");return 0;}
    if(!strcmp(mode,"max")){save(1,"comnig1",11);check_bmp("0:/bird_class/comnig1_2026.10.27/4294967295.bmp",11);ready(0,2,2000000,"comnig1",12);expect_error(SD_ARCHIVE_NUMBER_FULL);puts("MAX_NUMBER_NO_WRAP_PASS");return 0;}
    if(!strcmp(mode,"numbers")){save(1,"comnig1",19);check_bmp("0:/bird_class/comnig1_2026.10.27/24.bmp",19);puts("DECIMAL_CASE_JPG_JPEG_PNG_TMP_RESUME_PASS");return 0;}
    if(!strcmp(mode,"resume")){
        save(1,"comnig1",4);check_bmp("0:/bird_class/comnig1_2026.10.27/4.bmp",4);
        FIL old;UINT read;char text[12]={0};assert(f_open(&old,"0:/bird_class/comnig1_2026.10.27/1.bmp",FA_READ)==FR_OK);assert(f_read(&old,text,9,&read)==FR_OK && !memcmp(text,"old photo",9));assert(f_close(&old)==FR_OK);
        save(2,"eugwoo1",22);check_bmp("0:/bird_class/eugwoo1_2026.10.27/1.bmp",22);
        save(3,"comnig1",5);check_bmp("0:/bird_class/comnig1_2026.10.27/5.bmp",5);
        start();idle();save(1,"comnig1",6);check_bmp("0:/bird_class/comnig1_2026.10.27/6.bmp",6);
        textfile("0:/bird_class/DATE.TXT","2026.10.28");save(2,"comnig1",7);check_bmp("0:/bird_class/comnig1_2026.10.27/7.bmp",7);
        start();idle();save(1,"comnig1",8);check_bmp("0:/bird_class/comnig1_2026.10.28/1.bmp",8);
        puts("SPECIES_DAY_REBOOT_RESUME_NO_OVERWRITE_PASS");return 0;
    }
    assert(!strcmp(mode,"normal"));
    ready(0,2,2000000,"comnig1",32);ready(1,1,1000000,"comnig1",31);polls(1000);
    assert(sd_record_host_shared.consumer.saved==2);check_bmp("0:/bird_class/comnig1_2026.10.27/1.bmp",31);check_bmp("0:/bird_class/comnig1_2026.10.27/2.bmp",32);
    absent("0:/bird_class/comnig1_2026.10.27/1.tmp");assert(callback_count==yields && yields>500 && call_max<=8);
    printf("REAL_FAT32_LFN_CAPTURE_ORDER_PIXEL_BYTES_PASS reads=%u writes=%u yields=%u max_sectors=%u\n",reads,writes,yields,call_max);
    return 0;
}
