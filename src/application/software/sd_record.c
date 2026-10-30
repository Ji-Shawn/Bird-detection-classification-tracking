#include "sd_record.h"
#include "sd_species_codes.h"
#include <string.h>
static uint32_t boot_id, next_pixel, expected_offset, last_sequence;
static uint64_t current_time, last_target, last_capture;
static unsigned have_target, have_capture;
static int filling=-1;
static char current_code[12];
static uint32_t current_identity;
static uint64_t current_classified;
static unsigned label_valid(uint64_t now){
    return current_identity && current_code[0] && now>=current_classified && now-current_classified<=2000000u;
}
const char *sd_record_species_code(unsigned species){return species<60u?sd_species_codes[species]:0;}
void sd_record_label(const char *code,uint32_t identity,uint64_t classified,uint64_t now){
    unsigned length=0,valid=code && identity && now>=current_time && now>=classified && now-classified<=2000000u;
    if(valid){
        while(length<sizeof current_code && code[length]){
            unsigned c=(unsigned char)code[length];
            if(!((c>='a' && c<='z') || (c>='0' && c<='9'))){valid=0;break;}
            length++;
        }
        if(!length || length==sizeof current_code)valid=0;
    }
    if(!valid){current_identity=0;current_code[0]=0;current_classified=0;sd_record_frame_abort();return;}
    if(current_identity!=identity || strcmp(current_code,code))sd_record_frame_abort();
    memcpy(current_code,code,length+1u);current_identity=identity;current_classified=classified;
}
static void le16(uint8_t *p,unsigned v){p[0]=(uint8_t)v;p[1]=(uint8_t)(v>>8);}
static void le32(uint8_t *p,uint32_t v){for(unsigned i=0;i<4;i++)p[i]=(uint8_t)(v>>(i*8));}
static unsigned active(void){return have_target && current_time>=last_target && current_time-last_target<=2000000u;}
void sd_record_frame_abort(void){
    if(filling>=0){volatile sd_record_shared *m=sd_record_mailbox();
        sd_record_barrier();m->slot[filling].state=SD_SLOT_FREE;m->producer.dropped++;filling=-1;}
}
void sd_record_init(uint32_t boot){
    volatile sd_record_shared *m=sd_record_mailbox();
    /* Core0 calls this before AV_SHARED_READY publication / Core1 startup. */
    memset((void *)m,0,sizeof *m);boot_id=boot;filling=-1;
    have_target=have_capture=0;current_time=last_target=last_capture=0;
    current_identity=0;current_code[0]=0;current_classified=0;
    m->producer.boot=boot;sd_record_barrier();m->producer.magic=SD_RECORD_MAGIC;
}
void sd_record_target(unsigned formal,uint64_t now){
    if(now<current_time){have_target=have_capture=0;current_identity=0;current_code[0]=0;sd_record_frame_abort();}
    current_time=now;if(formal){last_target=now;have_target=1;}
    sd_record_mailbox()->producer.active=active();
    if(!active() || !label_valid(now))sd_record_frame_abort();
}
void sd_record_frame_begin(uint32_t sequence,uint64_t captured,uint64_t now){
    volatile sd_record_shared *m=sd_record_mailbox();sd_record_frame_abort();
    /* DMA admission happens after the service tick. Compare against the time
     * at admission, not the earlier target-service time. */
    if(now<current_time){have_target=have_capture=0;current_identity=0;current_code[0]=0;return;}
    current_time=now;
    /* Completed new camera frames only; stale/torn captures never become photos. */
    if(!active() || !label_valid(now) || captured>current_time || current_time-captured>500000u ||
       (have_capture && (sequence==last_sequence || captured<=last_capture || captured-last_capture<500000u)))return;
    sd_record_barrier();
    if(m->consumer.boot!=boot_id || m->consumer.state<SD_WRITER_IDLE || m->consumer.state==SD_WRITER_ERROR)return;
    for(unsigned i=0;i<2;i++)if(m->slot[i].state==SD_SLOT_FREE){filling=(int)i;break;}
    if(filling<0){m->producer.dropped++;return;}
    volatile sd_record_slot *s=&m->slot[filling];s->state=SD_SLOT_FILL;
    s->boot=boot_id;s->sequence=sequence;s->captured_us=captured;s->bytes=SD_RECORD_BMP_BYTES;
    memset((void *)s->ebird_code,0,sizeof s->ebird_code);
    memcpy((void *)s->ebird_code,current_code,strlen(current_code)+1u);
    s->target_identity=current_identity;s->classified_us=current_classified;
    next_pixel=expected_offset=0;last_sequence=sequence;last_capture=captured;have_capture=1;
    uint8_t *p=sd_record_payload((unsigned)filling);memset(p,0,54);p[0]='B';p[1]='M';
    le32(p+2,SD_RECORD_BMP_BYTES);le32(p+10,54);le32(p+14,40);le32(p+18,640);
    le32(p+22,(uint32_t)-360);le16(p+26,1);le16(p+28,24);le32(p+34,SD_RECORD_PIXELS*3);
    sd_record_flush(p,64);
}
void sd_record_frame_chunk(const void *chunk,uint32_t offset,uint32_t bytes){
    if(filling<0)return;
    if(offset!=expected_offset || !bytes || bytes>65536u || ((offset|bytes)&1u) ||
       offset>1920u*1080u*2u || bytes>1920u*1080u*2u-offset){sd_record_frame_abort();return;}
    const uint8_t *in=(const uint8_t *)chunk;
    uint8_t *out=sd_record_payload((unsigned)filling)+54+next_pixel*3u,*first=out;
    while(next_pixel<SD_RECORD_PIXELS){
        unsigned y=next_pixel/640u,x=next_pixel-y*640u;
        uint32_t at=(y*3u*1920u+x*3u)*2u;if(at>=offset+bytes)break;
        if(at<offset){sd_record_frame_abort();return;}
        uint16_t v=(uint16_t)(in[at-offset]|((unsigned)in[at-offset+1]<<8));
        unsigned r=(v>>11)&31u,g=(v>>5)&63u,b=v&31u;
        *out++=(uint8_t)((b<<3)|(b>>2));*out++=(uint8_t)((g<<2)|(g>>4));*out++=(uint8_t)((r<<3)|(r>>2));
        next_pixel++;
    }
    if(out!=first)sd_record_flush(first,(uint32_t)(out-first));
    expected_offset+=bytes;
}
void sd_record_frame_end(void){
    if(filling<0)return;
    if(expected_offset!=1920u*1080u*2u || next_pixel!=SD_RECORD_PIXELS || !active() || !label_valid(current_time)){
        sd_record_frame_abort();return;}
    volatile sd_record_shared *m=sd_record_mailbox();
    sd_record_barrier();m->slot[filling].state=SD_SLOT_READY;m->producer.produced++;filling=-1;
}
void sd_record_status(uint32_t w[SD_RECORD_WORDS]){
    volatile sd_record_shared *m=sd_record_mailbox();unsigned q=0;sd_record_barrier();
    unsigned state=m->consumer.state,ready=m->consumer.boot==boot_id && state>=SD_WRITER_IDLE && state<SD_WRITER_ERROR;
    for(unsigned i=0;i<2;i++)q+=m->slot[i].state!=SD_SLOT_FREE;
    w[0]=SD_RECORD_MAGIC;w[1]=1;w[2]=1u|(active()?2u:0u)|(ready?4u:0u)|
        (state>SD_WRITER_IDLE && state<SD_WRITER_ERROR?8u:0u)|(state==SD_WRITER_ERROR?16u:0u);
    w[3]=2000;w[4]=2000;w[5]=m->producer.produced;w[6]=m->consumer.saved;
    w[7]=m->producer.dropped;w[8]=q;w[9]=m->consumer.error;w[10]=m->consumer.bytes;w[11]=m->consumer.max_io_us;
}
