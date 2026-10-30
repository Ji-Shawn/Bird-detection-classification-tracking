#include "audio_model_input.h"
#include "av_shared.h"

#include <string.h>

static uint16_t history[AUDIO_MODEL_MEL_BINS][AUDIO_MODEL_TIME_FRAMES]
    __attribute__((aligned(64)));
static audio_model_tensor_t snapshot __attribute__((aligned(64)));
static uint32_t write_index;
static uint32_t valid_frames;
static uint32_t latest_sequence;
static uint64_t latest_timestamp_us;
static volatile uint32_t generation;

static void begin_update(void) {
    ++generation;
    if ((generation & 1u) == 0u) ++generation;
    av_memory_barrier();
}

static void end_update(void) {
    av_memory_barrier();
    ++generation;
}

void audio_model_tensor_reset(void) {
    begin_update();
    memset(history, 0, sizeof(history));
    memset(&snapshot, 0, sizeof(snapshot));
    write_index = 0u;
    valid_frames = 0u;
    latest_sequence = 0u;
    latest_timestamp_us = 0u;
    end_update();
}

void audio_model_tensor_push(const uint16_t mel[AUDIO_MODEL_MEL_BINS],
                             uint32_t sequence, uint64_t timestamp_us) {
    uint32_t band;
    if (mel == 0) return;
    begin_update();
    for (band = 0u; band < AUDIO_MODEL_MEL_BINS; ++band)
        history[band][write_index] = mel[band];
    write_index = (write_index + 1u) % AUDIO_MODEL_TIME_FRAMES;
    if (valid_frames < AUDIO_MODEL_TIME_FRAMES) ++valid_frames;
    latest_sequence = sequence;
    latest_timestamp_us = timestamp_us;
    end_update();
}

void audio_model_tensor_push_missing(uint32_t frames) {
    uint32_t band, frame;
    if (frames == 0u) return;
    if (frames > AUDIO_MODEL_TIME_FRAMES) frames = AUDIO_MODEL_TIME_FRAMES;
    begin_update();
    if (frames == AUDIO_MODEL_TIME_FRAMES) {
        memset(history, 0, sizeof(history));
        write_index = 0u;
        valid_frames = AUDIO_MODEL_TIME_FRAMES;
    } else {
        for (frame = 0u; frame < frames; ++frame) {
            for (band = 0u; band < AUDIO_MODEL_MEL_BINS; ++band)
                history[band][write_index] = 0u;
            write_index = (write_index + 1u) % AUDIO_MODEL_TIME_FRAMES;
            if (valid_frames < AUDIO_MODEL_TIME_FRAMES) ++valid_frames;
        }
    }
    end_update();
}

const audio_model_tensor_t *audio_model_tensor_acquire(void) {
    uint32_t band, time, count, padding, oldest;
    uint32_t start_generation, end_generation;
    do {
        do { start_generation = generation; } while (start_generation & 1u);
        av_memory_barrier();
        count = valid_frames;
        padding = AUDIO_MODEL_TIME_FRAMES - count;
        oldest = (write_index + AUDIO_MODEL_TIME_FRAMES - count) %
                 AUDIO_MODEL_TIME_FRAMES;
        for (band = 0u; band < AUDIO_MODEL_MEL_BINS; ++band) {
            memset(snapshot.mel[band], 0, padding * sizeof(uint16_t));
            for (time = 0u; time < count; ++time)
                snapshot.mel[band][padding + time] =
                    history[band][(oldest + time) % AUDIO_MODEL_TIME_FRAMES];
        }
        snapshot.sequence = latest_sequence;
        snapshot.valid_frames = count;
        snapshot.timestamp_us = latest_timestamp_us;
        av_memory_barrier();
        end_generation = generation;
    } while (start_generation != end_generation || (end_generation & 1u));
    return &snapshot;
}
