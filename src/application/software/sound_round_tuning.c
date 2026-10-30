#include "sound_round_tuning.h"
#include <string.h>

static sound_round_settings settings=SOUND_ROUND_SETTINGS_DEFAULTS;
static uint32_t ack_request,ack_status,applies,next_cache;
static struct {uint8_t payload[30];uint32_t request,status,valid;} cache[16];
static uint32_t be32(const uint8_t *p) {
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
void sound_round_tuning_init(uint64_t now) {
    const sound_round_settings defaults=SOUND_ROUND_SETTINGS_DEFAULTS;
    settings=defaults;ack_request=ack_status=applies=next_cache=0;
    memset(cache,0,sizeof cache);
    sound_round_publish_config((volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,
        0,now,&settings);
}
uint32_t sound_round_tuning_value(unsigned index) {
    switch(index) {
    case SOUND_ROUND_TUNE_CAPTURE:return settings.capture_ms;
    case SOUND_ROUND_TUNE_MIN_GAP:return settings.min_gap_ms;
    case SOUND_ROUND_TUNE_RESET_GAP:return settings.reset_gap_ms;
    case SOUND_ROUND_TUNE_PAUSE:return settings.pause_ms;
    default:return 0;
    }
}
uint32_t sound_round_tuning_revision(void){return settings.revision;}
int sound_round_tuning_command(uint32_t boot,const uint8_t *p,unsigned bytes,uint64_t now) {
    if(!p || bytes!=30u)return -1;
    uint32_t request=be32(p+10),status=0;ack_request=request;
    if(p[0]!=26u || p[1]!=1u){ack_status=2u;return -1;}
    if(!boot || be32(p+2)!=boot){ack_status=3u;return -1;}
    if(!request){ack_status=5u;return -1;}
    for(unsigned i=0;i<16u;i++)if(cache[i].valid && cache[i].request==request) {
        status=memcmp(cache[i].payload,p,30u)?6u:cache[i].status;
        if(status==1u)status=7u;
        ack_status=status;return status==7u?0:-1;
    }
    sound_round_settings candidate={settings.revision,be32(p+14),be32(p+18),be32(p+22),be32(p+26)};
    if(candidate.capture_ms<1000u || candidate.capture_ms>5000u ||
       candidate.min_gap_ms<1000u || candidate.min_gap_ms>10000u ||
       candidate.reset_gap_ms<2000u || candidate.reset_gap_ms>30000u ||
       candidate.pause_ms>30000u || candidate.min_gap_ms<candidate.capture_ms ||
       candidate.reset_gap_ms<=candidate.min_gap_ms)status=5u;
    if(be32(p+6)!=settings.revision || settings.revision==UINT32_MAX)status=4u;
    uint32_t generation;uint64_t resume,after;sound_round_settings previous;
    volatile sound_round_control *control=(volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR;
    if(!status && !sound_round_snapshot_config(control,&generation,&resume,&after,&previous))status=4u;
    if(!status) {
        candidate.revision++;settings=candidate;applies++;
        /* Keep an accepted round's existing deadline; changed pause applies
         * only to a later accepted bearing. A new generation resets old PCM. */
        sound_round_publish_config(control,resume,now,&settings);status=1u;
    }
    unsigned index=next_cache++&15u;
    memcpy(cache[index].payload,p,30u);cache[index].request=request;
    cache[index].status=status;cache[index].valid=1u;ack_status=status;
    return status==1u?0:-1;
}
void sound_round_tuning_status(uint32_t words[16],uint32_t boot,uint64_t now) {
    memset(words,0,16u*sizeof *words);words[0]=0x53525432u;words[1]=1u;
    words[2]=settings.revision;words[3]=ack_request;words[4]=ack_status;words[5]=boot;
    for(unsigned i=0;i<4u;i++)words[6+i]=sound_round_tuning_value(i);
    words[10]=applies;
    words[11]=sound_round_receipt_read_boot((const volatile sound_round_receipt *)(uintptr_t)SOUND_ROUND_RECEIPT_ADDR,boot);
    words[12]=settings.capture_ms*32u;words[13]=SOUND_ROUND_MODEL_SAMPLES-words[12];
    uint32_t generation;uint64_t resume,after;sound_round_settings current;
    if(sound_round_snapshot_config((const volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,
        &generation,&resume,&after,&current) && resume>now) {
        uint64_t delta=resume-now;
        uint64_t remaining=delta/1000u+(delta%1000u!=0);
        words[14]=remaining>UINT32_MAX?UINT32_MAX:(uint32_t)remaining;
    }
}
