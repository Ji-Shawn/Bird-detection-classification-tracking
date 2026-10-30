#include "audio_dsp.h"
#include "audio_array.h"

#include <math.h>
#include <string.h>

static const uint8_t pair_a[AUDIO_PAIR_COUNT] = AUDIO_ARRAY_PAIR_A;
static const uint8_t pair_b[AUDIO_PAIR_COUNT] = AUDIO_ARRAY_PAIR_B;
static const float mic_x[4] = AUDIO_ARRAY_X_METRES;
static const float mic_y[4] = AUDIO_ARRAY_Y_METRES;

static int solve_weighted(
    const tdoa_result_t *tdoa,
    uint8_t pair_mask,
    float *x,
    float *y,
    uint32_t *confidence_sum,
    uint32_t *pair_count) {
    const float sample_scale = (float)AUDIO_SAMPLE_RATE / AUDIO_SOUND_SPEED_M_S;
    float m00 = 0.0f, m01 = 0.0f, m11 = 0.0f;
    float v0 = 0.0f, v1 = 0.0f;
    uint32_t pair;

    *confidence_sum = 0U;
    *pair_count = 0U;
    for (pair = 0U; pair < AUDIO_PAIR_COUNT; ++pair) {
        float ax, ay, lag, weight;
        if ((pair_mask & (uint8_t)(1U << pair)) == 0U) continue;
        ax = -(mic_x[pair_a[pair]] - mic_x[pair_b[pair]]) * sample_scale;
        ay = -(mic_y[pair_a[pair]] - mic_y[pair_b[pair]]) * sample_scale;
        lag = (float)tdoa->lag_q8_8[pair] / 256.0f;
        weight = (float)tdoa->pair_confidence_q0_15[pair] / 32768.0f;
        if (weight <= 0.0f) continue;
        m00 += weight * ax * ax;
        m01 += weight * ax * ay;
        m11 += weight * ay * ay;
        v0 += weight * ax * lag;
        v1 += weight * ay * lag;
        *confidence_sum += tdoa->pair_confidence_q0_15[pair];
        ++*pair_count;
    }
    {
        const float determinant = m00 * m11 - m01 * m01;
        if ((*pair_count < 3U) || (determinant < 1.0e-4f)) return -1;
        *x = (v0 * m11 - v1 * m01) / determinant;
        *y = (m00 * v1 - m01 * v0) / determinant;
    }
    return 0;
}

int tdoa_to_direction(const tdoa_result_t *tdoa, direction_result_t *out) {
    const float sample_scale = (float)AUDIO_SAMPLE_RATE / AUDIO_SOUND_SPEED_M_S;
    uint8_t retained_mask;
    float x, y, norm, angle, residual_sum = 0.0f, rms;
    uint32_t confidence_sum, pair_count, pair;
    uint32_t confidence;
    if (tdoa == 0 || out == 0) return -1;
    memset(out, 0, sizeof(*out));
    memcpy(out->lag_q8_8, tdoa->lag_q8_8, sizeof(out->lag_q8_8));
    retained_mask = tdoa->valid_pair_mask;
    if (solve_weighted(tdoa, retained_mask, &x, &y, &confidence_sum, &pair_count) != 0) {
        return -2;
    }
    norm = sqrtf(x * x + y * y);
    /* x/y are horizontal direction cosines, not a unit vector when the
     * source has elevation. Check measured lags before normalizing. */
    if (norm < 0.25f || norm > 1.15f) return -3;

    for (pair = 0U; pair < AUDIO_PAIR_COUNT; ++pair) {
        float ax, ay, lag, residual;
        if ((retained_mask & (uint8_t)(1U << pair)) == 0U) continue;
        ax = -(mic_x[pair_a[pair]] - mic_x[pair_b[pair]]) * sample_scale;
        ay = -(mic_y[pair_a[pair]] - mic_y[pair_b[pair]]) * sample_scale;
        lag = (float)tdoa->lag_q8_8[pair] / 256.0f;
        residual = fabsf(ax * x + ay * y - lag);
        if (residual > AUDIO_GCC_RESIDUAL_LIMIT) {
            retained_mask &= (uint8_t)~(1U << pair);
        }
    }
    if (solve_weighted(tdoa, retained_mask, &x, &y, &confidence_sum, &pair_count) != 0) {
        return -4;
    }
    norm = sqrtf(x * x + y * y);
    if (norm < 0.25f || norm > 1.15f) return -5;

    for (pair = 0U; pair < AUDIO_PAIR_COUNT; ++pair) {
        float ax, ay, lag, residual;
        if ((retained_mask & (uint8_t)(1U << pair)) == 0U) continue;
        ax = -(mic_x[pair_a[pair]] - mic_x[pair_b[pair]]) * sample_scale;
        ay = -(mic_y[pair_a[pair]] - mic_y[pair_b[pair]]) * sample_scale;
        lag = (float)tdoa->lag_q8_8[pair] / 256.0f;
        residual = ax * x + ay * y - lag;
        residual_sum += residual * residual;
    }
    rms = sqrtf(residual_sum / (float)pair_count);
    if (rms >= AUDIO_GCC_RESIDUAL_LIMIT) return -6;
    angle = atan2f(x, y) * 57.29577951308232f;
    if (angle >= 180.0f) angle -= 360.0f;
    if (angle < -180.0f) angle += 360.0f;
    out->angle_q9_7 = (int16_t)lrintf(angle * 128.0f);
    confidence = (uint32_t)((float)(confidence_sum / pair_count) * expf(-rms * 0.5f));
    if (confidence > 32767U) confidence = 32767U;
    out->confidence_q0_15 = (uint16_t)confidence;
    out->residual_q8_8 = (uint16_t)lrintf(rms * 256.0f);
    out->valid = confidence > 512u;
    return out->valid ? 0 : -7;
}
