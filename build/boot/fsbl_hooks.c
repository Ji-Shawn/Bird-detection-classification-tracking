/* M50 SD handoff. Application ELFs and PL are the same pair used by JTAG. */
#include "fsbl.h"
#include "fsbl_hooks.h"
#include "xil_io.h"
#include "xstatus.h"
#include "m50_handoff_config.h"

u32 FsblHookBeforeBitstreamDload(void) { return XST_SUCCESS; }
u32 FsblHookAfterBitstreamDload(void) { return XST_SUCCESS; }

u32 FsblHookBeforeHandoff(void)
{
    /* Match the accepted J11 JTAG bootstrap; do not change vision/audio policy. */
    if (Xil_In32(0x43c00004U) != 0x0001000aU ||
        Xil_In32(0x43c00088U) != 0x53525631U)
        return XST_FAILURE;
    Xil_Out32(0x43c00080U, 2U);
    Xil_Out32(0x43c0007cU, 112068U); /* 1140 us, startup tilt 60 degrees. */
    Xil_Out32(0x43c00080U, 6U);
    Xil_Out32(0x41210000U, 1U);     /* HDMI stream enable. */
    Xil_Out32(0x3003f000U, 0U);     /* Core1 shared result is not ready yet. */
    Xil_Out32(M50_NETWORK_VIDEO_GAP_ADDRESS, 10U);
    __asm__ volatile ("dsb sy" ::: "memory");
    return XST_SUCCESS;
}

void FsblHookFallback(void)
{
    /* Keep the boot failure available for UART/JTAG diagnosis. */
    for (;;) { }
}
