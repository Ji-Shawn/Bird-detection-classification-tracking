#ifndef AUDIO_ETH_ADAPTER_H
#define AUDIO_ETH_ADAPTER_H
#include "av_shared.h"
#include "audio_dsp.h"
/* CPU1-only adapter to the frozen DDR result ABI. Does not send packets. */
void audio_eth_adapter_pack(av_audio_result_payload_t *out,
    const int16_t pcm[480], const uint16_t mel[128], const direction_result_t *direction);
#endif
