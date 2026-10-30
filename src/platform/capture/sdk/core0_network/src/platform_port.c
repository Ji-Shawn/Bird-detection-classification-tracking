#include "network_service.h"
#include "av_protocol.h"

#include "lwip/pbuf.h"
#include "lwip/etharp.h"
#include "lwip/udp.h"
#include "netif/xadapter.h"
#include "xil_cache.h"
#include "xil_exception.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xscugic.h"
#include "xtime_l.h"

#include <string.h>

static struct udp_pcb *tx_pcb;
static struct udp_pcb *control_pcb;
static ip_addr_t destination;
static struct netif board_netif;
static network_service_t *control_service;
static control_state_t control_state;
/* Internal JTAG counters only: calls, allocation/take/UDP errors, last lwIP
 * error, bytes accepted. Flush on status/error so live reads need no CPU halt. */
volatile uint32_t network_tx_diag[16] __attribute__((aligned(64)));

static uint16_t read_be16(const uint8_t *p) { return (uint16_t)(((uint16_t)p[0] << 8) | p[1]); }
static uint32_t read_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | p[3];
}
static uint32_t time_ms(void) {
    XTime now; XTime_GetTime(&now);
    return (uint32_t)(((uint64_t)now * 1000u) / COUNTS_PER_SECOND);
}
static void control_receive(void *arg, struct udp_pcb *pcb, struct pbuf *p,
                            const ip_addr_t *address, u16_t port) {
    uint8_t wire[512], command[257];
    av_packet_decoded_t decoded;
    uint16_t command_id, value_bytes;
    uint32_t command_sequence;
    control_result_t result;
    (void)arg; (void)pcb; (void)port;
    if (p == 0) return;
    if (p->tot_len > sizeof(wire) || pbuf_copy_partial(p, wire, p->tot_len, 0) != p->tot_len) {
        pbuf_free(p); return;
    }
    if (av_decode_packet(wire, p->tot_len, &decoded) != AV_DECODE_OK ||
        decoded.packet_type != AV_PACKET_CONTROL || decoded.payload_bytes < 8u) {
        pbuf_free(p); return;
    }
    command_id = read_be16(decoded.payload);
    value_bytes = read_be16(decoded.payload + 2);
    command_sequence = read_be32(decoded.payload + 4);
    if (command_id > 255u || value_bytes > 256u ||
        decoded.payload_bytes != (uint16_t)(8u + value_bytes)) {
        pbuf_free(p); return;
    }
    command[0] = (uint8_t)command_id;
    if (value_bytes) memcpy(command + 1, decoded.payload + 8, value_bytes);
    result = control_handle(control_service, &control_state, address->addr,
                            command_sequence, command, (uint16_t)(value_bytes + 1u), time_ms());
    (void)udp_send_control_reply(control_service, command_sequence, result);
    pbuf_free(p);
}

int network_platform_init(uint32_t destination_ipv4, network_service_t *service) {
    ip_addr_t local_ip, netmask, gateway;
    unsigned char mac[6] = {0x00u, 0x0Au, 0x35u, 0x70u, 0x20u, 0x01u};

    Xil_ExceptionInit();
    XScuGic_DeviceInitialize(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
        (Xil_ExceptionHandler)XScuGic_DeviceInterruptHandler,
        (void *)XPAR_SCUGIC_SINGLE_DEVICE_ID);
    Xil_ExceptionEnableMask(XIL_EXCEPTION_IRQ);

    IP4_ADDR(&local_ip, 192, 168, 7, 20);
    IP4_ADDR(&netmask, 255, 255, 255, 0);
    IP4_ADDR(&gateway, 192, 168, 7, 1);
    if (xemac_add(&board_netif, &local_ip, &netmask, &gateway, mac,
                  XPAR_XEMACPS_0_BASEADDR) == 0) return -1;
    netif_set_default(&board_netif);
    netif_set_up(&board_netif);

    tx_pcb = udp_new();
    if (tx_pcb == 0) return -2;
    destination.addr = destination_ipv4;
    control_service = service;
    memset(&control_state, 0, sizeof(control_state));
    control_state.allowed_ipv4 = destination_ipv4;
    control_state.sound_speed_mps = 343u;
    control_pcb = udp_new();
    if (control_pcb == 0 || udp_bind(control_pcb, IP_ADDR_ANY, AV_UDP_CONTROL_PORT) != ERR_OK) return -3;
    udp_recv(control_pcb, control_receive, 0);
    return 0;
}
void network_platform_poll(void) {
    static XTime last_arp;
    XTime now;
    (void)xemacif_input(&board_netif);
    XTime_GetTime(&now);
    if ((now - last_arp) >= (XTime)(5u * COUNTS_PER_SECOND)) {
        etharp_tmr();
        last_arp = now;
    }
}
int platform_udp_send(uint16_t port, const void *data, uint32_t bytes) {
    return platform_udp_send_parts(port, data, bytes, 0, 0);
}
int platform_udp_send_parts(uint16_t port, const void *header, uint32_t header_bytes,
                            const void *payload, uint32_t payload_bytes) {
    struct pbuf *p;
    err_t result;
    uint32_t bytes;
    if (header_bytes > 65535u || payload_bytes > 65535u-header_bytes ||
        (header_bytes && !header) || (payload_bytes && !payload)) return -3;
    bytes = header_bytes + payload_bytes;
    if (tx_pcb == 0) return -1;
    ++network_tx_diag[0];
    p = pbuf_alloc(PBUF_TRANSPORT, (u16_t)bytes, PBUF_RAM);
    if (p == 0) {
        ++network_tx_diag[1];
        Xil_DCacheFlushRange((UINTPTR)network_tx_diag,sizeof network_tx_diag);
        return NETWORK_SEND_RETRY;
    }
    if (pbuf_take(p, header, (u16_t)header_bytes) != ERR_OK ||
        (payload_bytes && pbuf_take_at(p, payload, (u16_t)payload_bytes,
                                      (u16_t)header_bytes) != ERR_OK)) {
        ++network_tx_diag[2];pbuf_free(p);return -3;
    }
    result = udp_sendto(tx_pcb, p, &destination, port);
    pbuf_free(p);
    if(result!=ERR_OK){++network_tx_diag[3];network_tx_diag[4]=(uint32_t)(int32_t)result;}
    else network_tx_diag[5]+=bytes;
    if(port==AV_UDP_STATUS_PORT || result!=ERR_OK)
        Xil_DCacheFlushRange((UINTPTR)network_tx_diag,sizeof network_tx_diag);
    return result==ERR_OK ? 0 : (result==ERR_MEM || result==ERR_BUF ? NETWORK_SEND_RETRY : -4);
}
uint32_t platform_time_us(void) {
    XTime ticks;XTime_GetTime(&ticks);
    return (uint32_t)((uint64_t)ticks*1000000u/COUNTS_PER_SECOND);
}
void platform_cache_flush(const void *address, uint32_t bytes) { Xil_DCacheFlushRange((INTPTR)address, bytes); }
void platform_cache_invalidate(const void *address, uint32_t bytes) { Xil_DCacheInvalidateRange((INTPTR)address, bytes); }
void platform_mmio_write(uint32_t address, uint32_t value) { Xil_Out32(address, value); }
uint32_t platform_mmio_read(uint32_t address) { return Xil_In32(address); }
