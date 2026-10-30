#include "audio_worker.h"
#include "audio_dsp.h"
#include "audio_array.h"
#include "audio_model_input.h"
#include "bird_frontend.h"
#include "audio_health.h"
#include "audio_eth_adapter.h"
#include "model_logmel32.h"
#include "fusion_bridge.h"
#include "audio_quality.h"
#include "av_regs.h"
#include "av_shared.h"
#include "sound_round_policy.h"

#include <math.h>
#include <stddef.h>
#include <string.h>

#ifndef AV_REG_BASE
#define AV_REG_BASE 0x43C00000u
#endif
#define GLOBAL_TIMER_HZ (666666666u / 2u)
#define HOP_DEADLINE_CYCLES ((GLOBAL_TIMER_HZ / AUDIO_SAMPLE_RATE) * AUDIO_HOP_SAMPLES)

extern int av_ring_claim_ready(av_shared_desc_t *desc);
extern void av_ring_release_free(av_shared_desc_t *desc);
extern int av_ring_publish(av_shared_desc_t *desc, const void *payload, uint32_t bytes,
                           uint32_t boot_id, uint32_t sequence, uint64_t timestamp_us);

static bird_frontend_state_t frontend;
static audio_health_t health;
static uint8_t previous_mask, history_hops, fallback_channel;
static uint8_t have_capture_timestamp;
static uint64_t last_capture_timestamp;
static int32_t healthy_raw[480][4];
volatile uint32_t audio_healthy_mask, audio_fallback_channel, audio_doa_ready;
static int32_t filtered_hop[BIRD_CHANNELS][BIRD_HOP_SAMPLES];
static int32_t filtered_window[BIRD_CHANNELS][AUDIO_FFT_SIZE];
static int32_t raw_window[BIRD_CHANNELS][AUDIO_FFT_SIZE];
static int32_t beamformed[480];
static int32_t model_beamformed[480];
static int16_t wire_pcm[480];
static uint16_t wire_mel[128];
static uint8_t model_stream_active;
static sound_round_reader model_round;
static fusion_direction_sample window_direction;
volatile uint32_t audio_direction_debug[16];
/* 60 ms fallback detects sustained sounds that energy VAD treats as background. */
volatile uint32_t audio_direction_probe_interval=4;
volatile uint32_t audio_model_ready;
audio_channel_quality_t audio_raw_quality[4];
volatile uint32_t audio_quality_generation;
static av_audio_result_payload_t processed;
static void reset_capture_history(void) {
    audio_health_reset(&health);
    bird_frontend_reset(&frontend);
    beamform_reset();
    audio_process_reset();
    memset(filtered_window,0,sizeof(filtered_window));
    memset(raw_window,0,sizeof(raw_window));
    model_logmel32_reset();model_stream_active=0;audio_model_ready=0;
    memset(&window_direction,0,sizeof window_direction);
    previous_mask=history_hops=fallback_channel=0;
    audio_healthy_mask=audio_doa_ready=0;
}
_Static_assert(sizeof(av_audio_result_payload_t) == 1280u,
               "audio result payload ABI changed");

static void append_filtered_history(
    const int32_t filtered[BIRD_CHANNELS][BIRD_HOP_SAMPLES]) {
    uint32_t channel;
    for (channel = 0U; channel < BIRD_CHANNELS; ++channel) {
        uint32_t i;
        memmove(raw_window[channel],raw_window[channel]+BIRD_HOP_SAMPLES,
                (AUDIO_FFT_SIZE-BIRD_HOP_SAMPLES)*sizeof(int32_t));
        for(i=0;i<BIRD_HOP_SAMPLES;++i)
            raw_window[channel][AUDIO_FFT_SIZE-BIRD_HOP_SAMPLES+i]=healthy_raw[i][channel];
        memmove(filtered_window[channel], filtered_window[channel] + BIRD_HOP_SAMPLES,
                (AUDIO_FFT_SIZE - BIRD_HOP_SAMPLES) * sizeof(int32_t));
        memcpy(filtered_window[channel] + (AUDIO_FFT_SIZE - BIRD_HOP_SAMPLES),
               filtered[channel], BIRD_HOP_SAMPLES * sizeof(int32_t));
    }
}

static av_shared_desc_t *input_desc(uint32_t index) {
    return (av_shared_desc_t *)(uintptr_t)(AV_PCM_DESC_BASE + index * sizeof(av_shared_desc_t));
}
static av_pcm_payload_t *input_payload(uint32_t index) {
    return (av_pcm_payload_t *)(uintptr_t)(AV_PCM_PAYLOAD_BASE + index * AV_PCM_SLOT_BYTES);
}
static av_shared_desc_t *output_desc(uint32_t index) {
    return (av_shared_desc_t *)(uintptr_t)(AV_RESULT_DESC_BASE + index * sizeof(av_shared_desc_t));
}
static av_audio_result_payload_t *output_payload(uint32_t index) {
    return (av_audio_result_payload_t *)(uintptr_t)(AV_RESULT_PAYLOAD_BASE + index * AV_RESULT_SLOT_BYTES);
}

static void commit_delays(const direction_result_t *direction, uint8_t mask) {
    float radians = ((float)direction->angle_q9_7 / 128.0f) * 0.017453292519943295f;
    float x = sinf(radians), y = cosf(radians);
    const float px[4] = AUDIO_ARRAY_X_METRES;
    const float py[4] = AUDIO_ARRAY_Y_METRES;
    float arrival[4], latest;
    uint32_t channel;
    uint32_t count=0;
    for(channel=0;channel<4u;++channel) count+=(mask>>channel)&1u;
    for (channel = 0; channel < 4u; ++channel)
        arrival[channel] = -(px[channel] * x + py[channel] * y) * (float)AUDIO_SAMPLE_RATE / AUDIO_SOUND_SPEED_M_S;
    latest = arrival[0];
    for (channel = 1; channel < 4u; ++channel) if (arrival[channel] > latest) latest = arrival[channel];
    for (channel = 0; channel < 4u; ++channel) {
        float delay = latest - arrival[channel];
        uint32_t integer = (uint32_t)delay;
        uint32_t fraction = (uint32_t)((delay - integer) * 32768.0f + 0.5f);
        if (integer > 34u) integer = 34u;
        if (fraction > 32767u) fraction = 32767u;
        platform_mmio_write(AV_REG_BASE + AV_REG_AUDIO_DELAY(channel), integer | (fraction << 6));
        platform_mmio_write(AV_REG_BASE + AV_REG_AUDIO_WEIGHT(channel),
            (mask & (1u<<channel)) ? 32768u/count : 0u);
    }
    platform_mmio_write(AV_REG_BASE + AV_REG_AUDIO_COMMIT, AV_COMMIT_REQUEST);
}

void audio_worker_init(audio_worker_state_t *state, uint32_t boot_id) {
    memset(state, 0, sizeof(*state));
    state->boot_id = boot_id;
    state->cycles_min = 0xFFFFFFFFu;
    have_capture_timestamp=0;
    last_capture_timestamp=0;
    memset(&model_round,0,sizeof model_round);
    sound_round_receipt_publish_boot((volatile sound_round_receipt *)(uintptr_t)SOUND_ROUND_RECEIPT_ADDR,0,boot_id);
    reset_capture_history();
    memset(filtered_hop, 0, sizeof(filtered_hop));
    memset(filtered_window, 0, sizeof(filtered_window));
    fft_q15_init();
    beamform_reset();
    audio_model_tensor_reset();
}

int audio_worker_poll(audio_worker_state_t *state) {
    av_shared_desc_t *in = input_desc(state->input_index);
    av_pcm_payload_t *pcm;
    av_shared_desc_t *out_desc;
    av_audio_result_payload_t *result;
    tdoa_result_t tdoa;
    direction_result_t direction;
    bird_vad_result_t vad;
    uint32_t start, elapsed, sample;
    uint32_t channel, healthy_count=0;
    uint8_t mask;
    if (!av_ring_claim_ready(in)) return 0;
    if (in->boot_id != state->boot_id) { state->stale_boot++; av_ring_release_free(in); return -1; }
    if (in->sequence != state->expected_sequence) {
        uint32_t missing = in->sequence - state->expected_sequence;
        state->sequence_gaps++;
        reset_capture_history();
        if (missing < 0x80000000u) audio_model_tensor_push_missing(missing);
        else audio_model_tensor_reset();
        state->expected_sequence = in->sequence;
    }
    /* Successful DMA captures have contiguous sequence IDs even after a reset.
     * Existing completion timestamps catch many unnumbered outages. A 1.5-hop
     * threshold catches a missing 15ms block, at the cost of conservative
     * resets under >7.5ms scheduling jitter. This is NOT a sample-index proof. */
    if(have_capture_timestamp && (in->timestamp_us<=last_capture_timestamp ||
        in->timestamp_us-last_capture_timestamp>22500u)) reset_capture_history();
    last_capture_timestamp=in->timestamp_us;
    have_capture_timestamp=1;
    pcm = input_payload(state->input_index);
    platform_cache_invalidate(pcm, sizeof(*pcm));
    start = platform_cycle_count();
    ++audio_quality_generation;
    av_memory_barrier();
    audio_quality_measure((const int32_t (*)[4])pcm->sample,audio_raw_quality);
    av_memory_barrier();
    ++audio_quality_generation;
    mask=audio_health_update(&health,pcm->sample);
    if(mask!=previous_mask) {
        memset(filtered_window,0,sizeof(filtered_window));
        /* No ringing from a disconnected/reconnected input in its filter. */
        bird_frontend_reset(&frontend);
        history_hops=0;
        previous_mask=mask;
    }
    for(channel=0;channel<4u;++channel) {
        healthy_count+=(mask>>channel)&1u;
        for(sample=0;sample<480u;++sample)
            healthy_raw[sample][channel]=(mask&(1u<<channel))?pcm->sample[sample][channel]:0;
    }
    (void)bird_frontend_process_hop(&frontend, healthy_raw, filtered_hop, &vad);
    append_filtered_history(filtered_hop);
    if(history_hops<3u) ++history_hops;
    audio_healthy_mask=mask;
    audio_doa_ready=(healthy_count>=3u && history_hops>=3u);
    if(healthy_count < 3u || history_hops<3u) vad.active=0;
    memset(&direction, 0, sizeof(direction));
    audio_direction_debug[0]++;audio_direction_debug[1]+=vad.active!=0;
    unsigned probe=audio_direction_probe_interval && healthy_count==4u && history_hops>=3u &&
        audio_direction_debug[0]%audio_direction_probe_interval==0;
    if (vad.active || probe) {
        state->vad_active_hops++;
        audio_direction_debug[2]++;
        if ((gcc_phat_4ch((const int32_t (*)[AUDIO_FFT_SIZE])filtered_window, &tdoa) != 0) ||
            (tdoa_to_direction(&tdoa, &direction) != 0)) {
            state->localization_failures++;audio_direction_debug[3]++;
            memset(&direction, 0, sizeof(direction));
        }
    }
    direction_result_t tracking_direction=direction;
    {
        volatile fusion_live_direction *live=(volatile fusion_live_direction *)FUSION_LIVE_DIRECTION;
        live->generation++;av_memory_barrier();live->mask=mask;
        live->sample.timestamp_us=in->timestamp_us;
        live->sample.angle_q9_7=tracking_direction.angle_q9_7;
        live->sample.confidence_q0_15=tracking_direction.confidence_q0_15;
        live->sample.valid=mask==15u && tracking_direction.valid;
        live->energy=(float)((vad.energy[0]+vad.energy[1]+vad.energy[2]+vad.energy[3])/4u);
        av_memory_barrier();live->generation++;
    }
    /* Periodic localization does not change the existing classifier/PCM beamforming policy. */
    if(!vad.active)memset(&direction,0,sizeof direction);
    if (direction.valid) {
        audio_direction_debug[4]++;
        beamform_set_direction(direction.angle_q9_7);
        commit_delays(&direction,mask);
    }
    if(!(mask & (1u<<fallback_channel))) {
        for(channel=0;channel<4u;++channel)
            if(mask & (1u<<channel)) { fallback_channel=(uint8_t)channel; break; }
    }
    audio_fallback_channel=mask?fallback_channel:0xffffffffu;
    beamform_set_channels(mask,fallback_channel,direction.valid);
    beamform_delay_sum((const int32_t (*)[AUDIO_FFT_SIZE])filtered_window, 544u, beamformed);
    audio_process_hop(beamformed, wire_pcm, wire_mel, vad.active);
    audio_eth_adapter_pack(&processed,wire_pcm,wire_mel,&direction);
    /* Keep healthy quiet intervals in each three-second capture window;
     * the model implementation pads it to the frozen five-second input.
     * With no reliable DOA, delay_sum selects the healthy fallback microphone;
     * it never uses a stale steering direction. Transport gaps or an unhealthy
     * selected source change invalidates the window, unlike bird pauses.
     * A stable healthy subset can still classify; no four-mic DOA is released. */
    unsigned round_reset;
    int collect=sound_round_collect(&model_round,
        (const volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,
        in->timestamp_us,&round_reset);
    if(round_reset) {
        model_logmel32_reset();model_stream_active=0;audio_model_ready=0;
        memset(&window_direction,0,sizeof window_direction);
        const volatile sound_round_control *control=
            (const volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR;
        /* Receipt follows reset and target adoption, including during a pause.
         * A torn read must never acknowledge the previous cached settings. */
        av_memory_barrier();
        if(model_round.initialized && model_round.version==control->generation &&
           !(control->generation&1u) &&
           !model_logmel32_set_capture_samples(model_round.capture_samples))
            sound_round_receipt_publish_boot((volatile sound_round_receipt *)(uintptr_t)SOUND_ROUND_RECEIPT_ADDR,
                model_round.revision,state->boot_id);
        else collect=0;
    }
    if(mask && history_hops>=3u && collect) {
        fusion_direction_sample previous_direction=window_direction;
        if(mask==15u && tracking_direction.valid) {
            window_direction=(fusion_direction_sample){in->timestamp_us,
                tracking_direction.angle_q9_7,tracking_direction.confidence_q0_15,1};
        }
        if(mask==15u)beamform_delay_sum((const int32_t (*)[AUDIO_FFT_SIZE])raw_window,544u,model_beamformed);
        else memcpy(model_beamformed,raw_window[fallback_channel]+544u,sizeof model_beamformed);
        uint32_t before=model_logmel32_ready();
        model_logmel32_push(model_beamformed,480u);model_stream_active=1;
        if(model_logmel32_ready()!=before) {
            uint64_t end=in->timestamp_us-(uint64_t)model_logmel32_tail_samples()*1000000u/AUDIO_SAMPLE_RATE;
            if(window_direction.timestamp_us>end)window_direction=previous_direction;
            audio_direction_debug[5]++;audio_direction_debug[6]+=window_direction.valid!=0;
            fusion_audio_publish(model_logmel32_data(),end,&window_direction);
            memset(&window_direction,0,sizeof window_direction);
        }
        audio_model_ready=model_logmel32_ready();
    } else if(model_stream_active) {
        model_logmel32_reset();model_stream_active=0;audio_model_ready=0;
        memset(&window_direction,0,sizeof window_direction);
    }
    audio_model_tensor_push(processed.mel, in->sequence, in->timestamp_us);
    /* Seqlock-protected diagnostics in the existing noncached shared section. */
    {
        volatile uint32_t *h=(volatile uint32_t *)FUSION_AUDIO_HEALTH;
        h[0]++;av_memory_barrier();h[1]=mask;h[2]=vad.active;h[3]=audio_model_ready;
        for(channel=0;channel<4;channel++) {
            uint32_t bits;memcpy(&bits,&audio_raw_quality[channel].rms,4);
            h[4+channel]=bits;h[8+channel]=audio_raw_quality[channel].clips;
            h[12+channel]=audio_raw_quality[channel].invalid;
        }
        av_memory_barrier();h[0]++;
    }
    out_desc = output_desc(state->output_index);
    result = output_payload(state->output_index);
    platform_cache_invalidate(out_desc, sizeof(*out_desc));
    if (out_desc->state != AV_DESC_FREE) {
        state->output_overrun++;
    } else {
        memcpy(result, &processed, sizeof(processed));
        if (av_ring_publish(out_desc, result, sizeof(*result), in->boot_id, in->sequence, in->timestamp_us))
            state->output_index = (state->output_index + 1u) % AV_RESULT_RING_SLOTS;
    }
    for (sample = 0; sample < 128u; ++sample) {
        platform_mmio_write(AV_REG_BASE + AV_REG_MEL_INDEX, sample);
        platform_mmio_write(AV_REG_BASE + AV_REG_MEL_DATA, processed.mel[sample]);
    }
    platform_mmio_write(AV_REG_BASE + AV_REG_MEL_AUDIO_SEQ, in->sequence);
    platform_mmio_write(AV_REG_BASE + AV_REG_MEL_COMMIT, AV_COMMIT_REQUEST);
    elapsed = platform_cycle_count() - start;
    if (elapsed < state->cycles_min) state->cycles_min = elapsed;
    if (elapsed > state->cycles_max) state->cycles_max = elapsed;
    state->cycles_ema = state->cycles_ema ? state->cycles_ema + ((int32_t)(elapsed - state->cycles_ema) >> 4) : elapsed;
    if (elapsed > HOP_DEADLINE_CYCLES) {
        volatile uint32_t *shared_deadline =
            (volatile uint32_t *)(uintptr_t)AV_SHARED_AUDIO_DEADLINE_ADDR;
        state->deadline_miss++;
        *shared_deadline = state->deadline_miss;
        platform_cache_flush((const void *)shared_deadline, sizeof(*shared_deadline));
    }
    state->expected_sequence = in->sequence + 1u;
    state->input_index = (state->input_index + 1u) % AV_PCM_RING_SLOTS;
    av_ring_release_free(in);
    return 1;
}
