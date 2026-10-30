#include "network_standalone.h"
#ifdef NETWORK_STANDALONE_HOST
#include "network_standalone_host.h"
#else
#include "netif/xemacpsif.h"
#endif

extern u32_t phyaddrforemac,link_speed;
extern enum ethernet_link_status eth_link_status;
/* Wrapper around the original BSP's static SLCR divider implementation. */
void network_standalone_clock(u32_t mac_baseaddr,unsigned speed);
volatile uint32_t network_standalone_speed,network_standalone_changes;
volatile uint32_t network_standalone_audio_dropped;
static uint32_t last_poll;
static unsigned polled;

static unsigned negotiated_speed(XEmacPs *emac,unsigned phy) {
    u16_t status,identity,speed;
    /* BMSR link is latched low: read twice before deciding. Registers and
     * decoding are identical to the BSP Realtek/Marvell/TI routines; this
     * observation never resets the PHY or restarts autonegotiation. */
    if(XEmacPs_PhyRead(emac,phy,1,&status)!=XST_SUCCESS ||
       XEmacPs_PhyRead(emac,phy,1,&status)!=XST_SUCCESS ||
       status==0xffffu || (status&0x24u)!=0x24u ||
       XEmacPs_PhyRead(emac,phy,2,&identity)!=XST_SUCCESS ||
       XEmacPs_PhyRead(emac,phy,17,&speed)!=XST_SUCCESS)return 0;
    if(identity==0x2000u) {
        unsigned bits=speed&0xc000u;
        return bits==0x8000u?1000u:bits==0x4000u?100u:bits==0u?10u:0u;
    }
    if(identity!=0x001cu && identity!=0x0141u)return 0;
    if(!(speed&0x0400u))return 0;
    unsigned bits=speed&0xc000u;
    return bits==0x8000u?1000u:bits==0x4000u?100u:bits==0u?10u:0u;
}

void network_standalone_init(struct netif *netif,uint32_t now_us) {
    network_standalone_speed=network_standalone_changes=0;
    network_standalone_audio_dropped=0;
    polled=0;last_poll=now_us;
    network_standalone_poll(netif,now_us);
}

void network_standalone_poll(struct netif *netif,uint32_t now_us) {
    if(polled && (uint32_t)(now_us-last_poll)<250000u)return;
    polled=1;last_poll=now_us;
    if(!netif || !netif->state)return;
    struct xemac_s *mac=(struct xemac_s *)netif->state;
    if(!mac->state)return;
    xemacpsif_s *port=(xemacpsif_s *)mac->state;
    XEmacPs *emac=&port->emacps;
    if(emac->IsReady!=XIL_COMPONENT_IS_READY)return;
    unsigned speed=negotiated_speed(emac,phyaddrforemac);
    if(speed!=network_standalone_speed)network_standalone_changes++;
    if(!speed) {
        network_standalone_speed=0;
        eth_link_status=ETH_LINK_DOWN;
        if(netif_is_link_up(netif))netif_set_link_down(netif);
        return;
    }
    if(speed!=network_standalone_speed || !netif_is_link_up(netif)) {
        network_standalone_clock(emac->Config.BaseAddress,speed);
        XEmacPs_SetOperatingSpeed(emac,(u16_t)speed);
        link_speed=speed;network_standalone_speed=speed;
        eth_link_status=ETH_LINK_UP;
        netif_set_link_up(netif);
    }
}
