#ifndef M48_NETWORK_STANDALONE_H
#define M48_NETWORK_STANDALONE_H
#include <stdint.h>
struct netif;
void network_standalone_init(struct netif *netif,uint32_t now_us);
void network_standalone_poll(struct netif *netif,uint32_t now_us);
/* Read-only diagnostics: negotiated Mbps (zero means no usable link). */
extern volatile uint32_t network_standalone_speed;
extern volatile uint32_t network_standalone_changes;
extern volatile uint32_t network_standalone_audio_dropped;
#endif
