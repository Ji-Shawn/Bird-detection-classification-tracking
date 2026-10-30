/* Actual SSD archive policy -> recorder -> actual FatFs; no physical device. */
#define main retained_archive_fixture_main
#include "test_sd_archive.c"
#undef main
#include "ssd_fast.h"
#include <math.h>

static unsigned case_count;
static const float bird_box[4]={500,300,800,600};
const uint8_t *ssd_history_exact(uint32_t sequence,uint64_t timestamp){(void)sequence;(void)timestamp;return 0;}
const uint8_t *ssd_history_next(uint64_t after,uint32_t *sequence,uint64_t *timestamp){(void)after;(void)sequence;(void)timestamp;return 0;}
void servo_tracking_sound_candidate(unsigned present,uint64_t now){(void)present;(void)now;}
int platform_udp_send(unsigned port,const void *data,unsigned bytes){(void)port;(void)data;(void)bytes;return 0;}

static uint32_t select_score(unsigned reason,float score,uint32_t seq,uint64_t ts,uint64_t now){
    ssd_fast_selection(reason,score,bird_box,seq,ts,now);
    return ssd_fast_archive_identity(seq,ts,1);
}
static void classify(uint32_t id,uint32_t seq,uint64_t ts,uint64_t now,float confidence){
    int8_t logits[60]={0};int32_t roi[4]={0};
    ssd_fast_class_store(seq,ts,1,now,logits,confidence,roi,1);
    ssd_fast_archive_store(id,seq,ts,1,now,0,0);
}
static int named(uint64_t now,uint64_t *classified){
    uint32_t species=99,id=0;uint64_t completed=0;
    int found=ssd_fast_archive_snapshot(now,&species,&id,&completed);
    if(found){assert(species==0 && id);if(classified)*classified=completed;}
    return found;
}
static void single_score(float score,float class_confidence,int expected){
    ssd_fast_init(1);uint32_t id=select_score(3,score,1,1000000,1100000);
    classify(id,1,1000000,1200000,class_confidence);
    assert(named(1200000,0)==expected);case_count++;
}
static void policy_cases(void){
    single_score(.9499f,.99f,0); /* 94.99 percent, high species confidence. */
    single_score(.95f,.99f,1);
    single_score(.9501f,.99f,1);
    single_score(1.f,.99f,1);
    single_score(.95f,.01f,1); /* Species confidence is not the SSD gate. */
    single_score(.8f,.99f,0); /* Previous 80 percent threshold is now rejected. */
    single_score(.9f,.99f,0); /* High species confidence cannot make 90 percent SSD eligible. */
    single_score(.5001f,.99f,0);
    single_score(.5f,.99f,0);
    single_score(0.f,.99f,0);
    single_score(-.1f,.99f,0);
    single_score(1.0001f,.99f,0);
    single_score(NAN,.99f,0);
    single_score(INFINITY,.99f,0);
    single_score(-INFINITY,.99f,0);

    ssd_fast_init(1);uint32_t id=select_score(3,.99f,1,1000000,1100000);
    assert(id && !named(1100000,0));case_count++; /* No visual species yet. */
    classify(id,1,1000000,1200000,.99f);assert(named(1200000,0));
    assert(select_score(2,.6f,2,1500000,1600000)==id);
    assert(ssd_fast_archive_identity(2,1500000,1)==id); /* Original >50 selection stays accepted. */
    assert(!named(1600000,0));case_count++;
    int8_t output[60];int32_t roi[4];uint32_t applied;
    assert(ssd_fast_class_reuse(2,1500000,1,1600000,output,roi,&applied));
    ssd_fast_archive_store(id,2,1500000,1,1600000,0,1);
    assert(!named(1600000,0));case_count++; /* Reused class never bypasses low SSD. */
    assert(select_score(2,.95f,3,1800000,1900000)==id);
    uint64_t completed=0;assert(named(1900000,&completed) && completed==1200000);case_count++;
    assert(ssd_fast_class_reuse(3,1800000,1,2000000,output,roi,&applied));
    ssd_fast_archive_store(id,3,1800000,1,2000000,0,1);
    assert(named(3200000,&completed) && completed==1200000);
    assert(!named(3200001,0));case_count++; /* Exactly original two-second class TTL. */

    ssd_fast_init(1);select_score(1,1.f,1,1000000,1100000);
    assert(!ssd_fast_archive_identity(1,1000000,1) && !named(1100000,0));case_count++;
    id=select_score(3,.99f,2,1200000,1300000);classify(id,2,1200000,1400000,.99f);
    assert(named(1400000,0));
    select_score(1,1.f,3,1500000,1600000);ssd_fast_poll(1600000);
    assert(!named(1600000,0));case_count++; /* A high candidate/NCC poll cannot qualify. */
    for(unsigned reason=0;reason<=6;reason++)if(reason==0 || reason==5 || reason==6){
        ssd_fast_init(1);id=select_score(3,.99f,1,1000000,1100000);classify(id,1,1000000,1200000,.99f);
        select_score(reason,.99f,2,1300000,1400000);assert(!named(1400000,0));case_count++;
    }
    ssd_fast_init(1);id=select_score(3,.99f,1,1000000,1100000);classify(id,1,1000000,1200000,.99f);
    ssd_fast_reset();assert(!named(1300000,0));case_count++;
    ssd_fast_init(1);id=select_score(3,.99f,1,1000000,1100000);classify(id,1,1000000,1200000,.99f);
    assert(!named(999999,0));case_count++;
    ssd_fast_init(1);id=select_score(3,.99f,1,1000000,1000000);classify(id,1,1000000,5900000,.99f);
    assert(named(6000000,0));assert(!named(6000001,0));case_count++;
    ssd_fast_init(1);id=select_score(3,.99f,1,1000000,6000001);classify(id,1,1000000,6000001,.99f);
    assert(!named(6000001,0));case_count++;
    ssd_fast_init(1);id=select_score(3,.99f,1,2000000,1000000);classify(id,1,2000000,2100000,.99f);
    assert(!named(2100000,0));case_count++;
    ssd_fast_init(1);id=select_score(3,.99f,1,0,1000000);classify(id,1,0,1100000,.99f);
    assert(!named(1100000,0));case_count++;
    ssd_fast_init(1);id=select_score(3,.99f,1,1000000,1100000);classify(id,1,1000000,1200000,.99f);
    const float invalid_box[4]={500,300,499,600};
    ssd_fast_selection(2,1.f,invalid_box,2,1300000,1400000);
    assert(!named(1400000,0));case_count++;
    puts("M51_SSD95_POLICY_BOUNDARIES_PASS");
}

/* This is the same read-only metadata bridge as the generated service hook. */
static void record_service(uint64_t now){
    uint32_t species=0,id=0;uint64_t completed=0;
    int valid=ssd_fast_archive_snapshot(now,&species,&id,&completed);
    sd_record_label(valid?sd_record_species_code(species):0,id,completed,now);
    sd_record_target(1,now);
}
static void pixels(void){
    static uint8_t rgb565[65536];memset(rgb565,255,sizeof rgb565);
    for(uint32_t offset=0;offset<1920u*1080u*2u;){
        uint32_t n=1920u*1080u*2u-offset;if(n>sizeof rgb565)n=sizeof rgb565;
        sd_record_frame_chunk(rgb565,offset,n);offset+=n;
    }
}
static void capture_frame(unsigned seq,uint64_t now){
    record_service(now);sd_record_frame_begin(seq,now,now);pixels();sd_record_frame_end();
}
static void integrated_cases(void){
    seed_date("1999.12.31\r\n");sd_record_init(1);sd_writer_init(1,audio_yield,&callback_count);idle();ssd_fast_init(1);
    uint32_t id=select_score(3,.9499f,1,1000000,1000000);classify(id,1,1000000,1000001,.99f);
    capture_frame(1,1100000);polls(500);
    assert(!sd_record_host_shared.producer.produced && !sd_record_host_shared.consumer.saved);
    absent("0:/bird_class/amecro_1999.12.31");case_count++;

    assert(select_score(2,.95f,2,1500000,1500000)==id);
    capture_frame(2,1600000);polls(1000);
    assert(sd_record_host_shared.producer.produced==1 && sd_record_host_shared.consumer.saved==1);
    check_bmp("0:/bird_class/amecro_1999.12.31/1.bmp",255);case_count++;

    record_service(2100000);sd_record_frame_begin(3,2100000,2100000);pixels();
    assert(sd_record_host_shared.slot[0].state==SD_SLOT_FILL || sd_record_host_shared.slot[1].state==SD_SLOT_FILL);
    assert(select_score(2,.94f,3,2100010,2100010)==id);record_service(2100020);sd_record_frame_end();polls(500);
    assert(sd_record_host_shared.producer.produced==1 && sd_record_host_shared.consumer.saved==1);
    absent("0:/bird_class/amecro_1999.12.31/2.bmp");case_count++;

    assert(select_score(2,.9501f,4,2600000,2600000)==id);capture_frame(4,2700000);polls(1000);
    assert(sd_record_host_shared.producer.produced==2 && sd_record_host_shared.consumer.saved==2);
    check_bmp("0:/bird_class/amecro_1999.12.31/2.bmp",255);case_count++;
    capture_frame(5,3300000);polls(500);
    assert(sd_record_host_shared.producer.produced==2 && sd_record_host_shared.consumer.saved==2);
    absent("0:/bird_class/amecro_1999.12.31/3.bmp");case_count++;
    assert(call_max<=8 && callback_count==yields && yields>0);
    puts("M51_SSD95_REAL_PRODUCER_FATFS_RECORD_GATE_PASS");
}
int main(int argc,char **argv){
    assert(argc==2);FILE *f=fopen(argv[1],"rb");assert(f && fread(vbr,1,512,f)==512);fclose(f);
    for(unsigned i=0;i<CACHE;i++)cache[i].sector=0xffffffffu;
    policy_cases();integrated_cases();
    printf("M51_SSD95_RECORD_NATIVE_PASS %u cases\n",case_count);
    return 0;
}
