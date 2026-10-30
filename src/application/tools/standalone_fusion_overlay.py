"""Persistent M48 SD startup and explicit control ownership integration.

These overlays apply after the M47 overlays. The same generated sources and
ELFs are used for both JTAG and SD; only the one-use boot marker differs.
"""


def once(text, old, new):
    if text.count(old) != 1:
        raise AssertionError(('M48 standalone anchor count', old, text.count(old)))
    return text.replace(old, new, 1)


OLD_AMP = '''    /* SD image preloads both ELFs; JTAG starts CPU1 explicitly instead. */
    if(*(volatile uint32_t *)0x30F01004u==0x4D323842u) {
        *(volatile uint32_t *)0x30F01004u=0;
        Xil_SetTlbAttributes(0xFFFF0000u,0x14de2u);
        *(volatile uint32_t *)0xFFFFFFF0u=0x08000000u;
        __asm__ volatile("dmb sy; sev" ::: "memory");
    }
'''

STARTUP = '''    /* Both boot paths execute this same ELF. SD's markers are one-use;
     * JTAG explicitly writes zeros before starting Core0. Read and clear the
     * DDR marker line with cache maintenance before releasing the other CPU. */
    {
        volatile uint32_t *markers=(volatile uint32_t *)(uintptr_t)0x30F01004u;
        uint32_t amp,autofusion;
        Xil_DCacheInvalidateRange((UINTPTR)markers,2u*sizeof(uint32_t));
        amp=markers[0];autofusion=markers[1];
        markers[0]=markers[1]=0u;
        Xil_DCacheFlushRange((UINTPTR)markers,2u*sizeof(uint32_t));
        __asm__ volatile("dsb sy" ::: "memory");
        if(amp==0x4D323842u) {
            Xil_SetTlbAttributes(0xFFFF0000u,NORM_NONCACHE);
            *(volatile uint32_t *)(uintptr_t)0xFFFFFFF0u=0x08000000u;
            __asm__ volatile("dsb sy; sev" ::: "memory");
        }
        XTime_GetTime(&now);
        standalone_fusion_start(autofusion,camera_status==0,
            (uint64_t)now*1000000u/COUNTS_PER_SECOND);
    }
'''


def apply_main(text):
    if 'standalone_fusion_start(' in text:
        raise AssertionError('M48 main overlay applied twice')
    text='#include "standalone_fusion.h"\n'+text
    if OLD_AMP in text:
        text=once(text,OLD_AMP,'')
    elif '0x30F01004' in text:
        raise AssertionError('Unknown previous AMP startup block')
    return once(text,'    for (;;) {',STARTUP+'    for (;;) {')


def apply_fusion(text):
    if 'standalone_fusion_poll(' in text:
        raise AssertionError('M48 fusion overlay applied twice')
    text='#include "standalone_fusion.h"\n'+text
    return once(text,'    servo_tracking_tick(t);',
        '    standalone_fusion_poll();\n    servo_tracking_tick(t);')


def apply_control(text):
    if 'standalone_fusion_command(' in text:
        raise AssertionError('M48 control overlay applied twice')
    text='#include "standalone_fusion.h"\n'+text
    return once(text,'    result = apply_command(service, control, payload, bytes);',
        '    result = apply_command(service, control, payload, bytes);\n'
        '    standalone_fusion_command(payload,bytes,result==CONTROL_APPLIED);')
