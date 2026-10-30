"""Estimate PCM sample times; preserve explicit physical-gap indications."""
PREFIX='#include "audio_capture_clock.h"\n'
REPLACEMENTS=[
 ('static uint32_t audio_sequence;', 'static uint32_t audio_sequence;\nstatic audio_capture_clock audio_clock;'),
 ('static int recover_audio_dma(void) {',
  'static int recover_audio_dma(void) {\n    audio_capture_clock_break(&audio_clock);'),
 ('audio_slot = audio_sequence = video_sequence = 0u;',
  'audio_slot = audio_sequence = video_sequence = 0u;\n    memset(&audio_clock,0,sizeof audio_clock);'),
 ('                network_audio_dma_complete(audio_slot, dma_boot_id,\n                                           audio_sequence++, timestamp_us());',
  '''                uint64_t completed=timestamp_us();unsigned gap=0;
                uint64_t sampled=audio_capture_clock_stamp(&audio_clock,completed,
                    platform_mmio_read(AV_REG_BASE+AV_REG_ERROR_COUNT),&gap);
                if(gap)audio_sequence++; /* Core1 rejects real discontinuities. */
                network_audio_dma_complete(audio_slot,dma_boot_id,audio_sequence++,sampled);
                volatile uint32_t *clock_diag=(volatile uint32_t *)0x30070100u;
                clock_diag[0]++;av_memory_barrier();
                clock_diag[1]=0x41544331u;clock_diag[2]=audio_sequence;
                clock_diag[3]=audio_clock.discontinuities;
                clock_diag[4]=audio_clock.delayed_callbacks;clock_diag[5]=audio_clock.errors;
                clock_diag[6]=(uint32_t)sampled;clock_diag[7]=(uint32_t)(sampled>>32);
                clock_diag[8]=(uint32_t)completed;clock_diag[9]=(uint32_t)(completed>>32);
                av_memory_barrier();clock_diag[0]++;'''),
]

def apply(text):
    for old,new in REPLACEMENTS:
        assert text.count(old)==1,old
        text=text.replace(old,new,1)
    return PREFIX+text

def revert(text):
    assert text.count(PREFIX)==1
    text=text.replace(PREFIX,'',1)
    for old,new in reversed(REPLACEMENTS):
        assert text.count(new)==1,new
        text=text.replace(new,old,1)
    return text
