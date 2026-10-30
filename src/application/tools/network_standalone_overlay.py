"""Keep the original PHY setup but do not make standalone boot wait for a PC.

Compile apply_phy() output as a separate object ahead of liblwip4. The original
archive and BSP source stay intact. Its public PHY symbols replace that one
archive member. Runtime link observation uses no reset or negotiation loops.
"""
import re


def once(text,old,new):
    assert text.count(old)==1,('M48 network anchor',old,text.count(old))
    return text.replace(old,new,1)


RESET_HELPER='''
/* A PHY reset is independent of a network partner. Bound a faulty MDIO/PHY
 * instead of waiting forever; negotiation itself continues in hardware. */
static int m48_phy_reset_ready(XEmacPs *emac,u32_t phy) {
    u16_t control;
    for(unsigned tries=0;tries<10000u;tries++) {
        if(XEmacPs_PhyRead(emac,phy,IEEE_CONTROL_REG_OFFSET,&control)!=XST_SUCCESS)
            return 0;
        if(!(control&IEEE_CTRL_RESET_MASK))return 1;
        usleep(10u);
    }
    return 0;
}
'''


def apply_phy(text):
    assert 'm48_phy_reset_ready' not in text
    text=once(text,'#include "xemac_ieee_reg.h"',
              '#include "xemac_ieee_reg.h"\n'+RESET_HELPER)
    for name in ('get_TI_phy_speed','get_Marvell_phy_speed','get_Realtek_phy_speed'):
        match=re.search(r'static u32_t '+name+r'\([^\n]+\)\n\{.*?\n\}',text,re.S)
        assert match,('Missing BSP PHY function',name)
        old=match[0];new=old
        new=once(new,'\tu32_t timeout_counter = 0;\n','')
        wait=re.search(r'\twhile \( !\(status & IEEE_STAT_AUTONEGOTIATE_COMPLETE\) \) \{.*?\n\t\}\n',new,re.S)
        assert wait,('Missing BSP negotiation wait',name)
        new=once(new,wait[0],
            '\t/* M48: no cable/partner must not block camera and SD startup. */\n'
            '\tif(!(status&IEEE_STAT_AUTONEGOTIATE_COMPLETE))return XST_FAILURE;\n')
        if name!='get_TI_phy_speed':
            reset=re.search(r'\twhile \(1\) \{.*?\n\t\}\n',new,re.S)
            assert reset,('Missing BSP reset wait',name)
            new=once(new,reset[0],
                '\tif(!m48_phy_reset_ready(xemacpsp,phy_addr))return XST_FAILURE;\n')
        text=once(text,old,new)
    # This exact fragment belongs only to the Zynq RGMII function. Returning
    # XST_FAILURE (1) would reach XEmacPs_SetOperatingSpeed and assert forever.
    text=once(text,
        '\tlink_speed = get_IEEE_phy_speed(xemacpsp, phy_addr);\n\tif (link_speed == 1000) {',
        '\tlink_speed = get_IEEE_phy_speed(xemacpsp, phy_addr);\n'
        '\t/* Valid temporary MAC clock while PHY negotiates; runtime link\n'
        '\t * stays DOWN until the real negotiated speed is observed. */\n'
        '\tif(link_speed!=10u && link_speed!=100u && link_speed!=1000u)link_speed=1000u;\n'
        '\tif (link_speed == 1000) {')
    return text+'''
/* Reuse the BSP's board-specific divider constants for hot-plug speed. */
void network_standalone_clock(u32_t mac_baseaddr,unsigned speed) {
    if(speed==10u || speed==100u || speed==1000u)
        SetUpSLCRDivisors(mac_baseaddr,(s32_t)speed);
}
'''


def apply_platform(text):
    assert 'network_standalone_init(' not in text
    text='#include "network_standalone.h"\n'+text
    text=once(text,'    netif_set_up(&board_netif);',
        '    netif_set_up(&board_netif);\n'
        '    network_standalone_init(&board_netif,platform_time_us());')
    text=once(text,'    (void)xemacif_input(&board_netif);',
        '    network_standalone_poll(&board_netif,platform_time_us());\n'
        '    (void)xemacif_input(&board_netif);')
    return once(text,'    if (tx_pcb == 0) return -1;',
        '    if (tx_pcb == 0) return -1;\n'
        '    /* Drop preview packets while unplugged; never fill the shared\n'
        '     * queues and stall camera/NCC waiting for a network partner. */\n'
        '    if (!netif_is_link_up(&board_netif)) return -4;')


def apply_udp(text):
    """Release only the optional network copy; local fusion has its own slot."""
    text='#include "network_standalone.h"\n'+text
    return once(text,
        '    platform_cache_invalidate(result, sizeof(*result));\n    packet_bytes = make_packet(AV_PACKET_PCM',
        '    platform_cache_invalidate(result, sizeof(*result));\n'
        '    /* The Core1 result ring is a network presentation copy. Audio\n'
        '     * classification/fusion uses FUSION_SHARED independently. Do not\n'
        '     * hold this ring forever when no Ethernet partner is present. */\n'
        '    if(!network_standalone_speed) {\n'
        '        network_standalone_audio_dropped++;\n'
        '        av_memory_barrier();desc->state=AV_DESC_FREE;\n'
        '        platform_cache_flush(desc,sizeof(*desc));\n'
        '        return 0; /* consumed locally, no packets/bytes_sent increase */\n'
        '    }\n'
        '    packet_bytes = make_packet(AV_PACKET_PCM')


def apply_scheduler(text):
    """Bound optional network presentation retries without delaying local work."""
    text='#include "network_standalone.h"\n'+text
    text=once(text,'static unsigned video_send_seen;',
        'static unsigned video_send_seen;\n'
        'static unsigned audio_retry_active;\n'
        'static uint32_t audio_retry_started,audio_retry_index,audio_retry_sequence;')
    text=once(text,'    video_send_seen=0;',
        '    video_send_seen=0;audio_retry_active=0;')
    text=once(text,'    video_frame_t *active_frame = 0;',
        '    video_frame_t *active_frame = 0;\n'
        '    if(!network_standalone_speed) {\n'
        '        for(slot=0;slot<NETWORK_VIDEO_PENDING;slot++) {\n'
        '            if(service->video[slot].valid)service->video_drop_tx++;\n'
        '            service->video[slot].valid=0;\n'
        '        }\n'
        '    }')
    return once(text,
        '        if (udp_send_audio_result(service, service->audio_read_index) != 0) {\n'
        '            audio->state = AV_DESC_READY; platform_cache_flush(audio, sizeof(*audio));\n'
        '            return -1;\n'
        '        }\n'
        '        service->audio_read_index = (service->audio_read_index + 1u) % AV_RESULT_RING_SLOTS;\n'
        '        return 1;',
        '        if (udp_send_audio_result(service, service->audio_read_index) != 0) {\n'
        '            uint32_t now=platform_time_us();\n'
        '            if(!audio_retry_active || audio_retry_index!=service->audio_read_index ||\n'
        '               audio_retry_sequence!=audio->sequence) {\n'
        '                audio_retry_active=1;audio_retry_started=now;\n'
        '                audio_retry_index=service->audio_read_index;audio_retry_sequence=audio->sequence;\n'
        '            }\n'
        '            if((uint32_t)(now-audio_retry_started)>=20000u) {\n'
        '                audio->state=AV_DESC_FREE;audio_retry_active=0;\n'
        '                service->audio_read_index=(service->audio_read_index+1u)%AV_RESULT_RING_SLOTS;\n'
        '                network_standalone_audio_dropped++;\n'
        '            } else audio->state=AV_DESC_READY;\n'
        '            platform_cache_flush(audio,sizeof(*audio));\n'
        '            /* A missing PC must not starve video/SD/NCC behind this\n'
        '             * optional monitor copy, even when Ethernet link is up. */\n'
        '        } else {\n'
        '            audio_retry_active=0;\n'
        '            service->audio_read_index=(service->audio_read_index+1u)%AV_RESULT_RING_SLOTS;\n'
        '            return 1;\n'
        '        }')
