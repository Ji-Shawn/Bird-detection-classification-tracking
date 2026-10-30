#include "standalone_fusion.h"
#include "fusion_bridge.h"
#include "servo_tracking.h"

volatile uint32_t standalone_fusion_state;
volatile uint32_t standalone_fusion_last_command;

void standalone_fusion_start(uint32_t request, unsigned camera_ready, uint64_t now) {
    uint32_t status[10],config[16],limits[8];
    standalone_fusion_state=STANDALONE_FUSION_DISABLED;
    standalone_fusion_last_command=0;
    if(request!=STANDALONE_FUSION_BOOT_MAGIC)return;
    if(!camera_ready) {
        standalone_fusion_state=STANDALONE_FUSION_CAMERA_FAILED;
        return;
    }
    /* Camera startup may take seconds. Use the same current-time preflight as
     * a received enable command, not the earlier fusion_init timestamp. */
    servo_tracking_tick(now);
    servo_tracking_status(status);
    servo_tracking_config_status(config);
    servo_tracking_limit_status(limits);
    if(!status[1] || !config[13] || !config[14] || !limits[2]) {
        standalone_fusion_state=STANDALONE_FUSION_START_FAILED;
        return;
    }
    /* Exact command-15 mode-2 sequence: no alternate tracking algorithm. */
    if(fusion_set_image_policy(1,0) || fusion_set_mode(2) || servo_tracking_auto(2)) {
        servo_tracking_stop();
        standalone_fusion_state=STANDALONE_FUSION_START_FAILED;
        return;
    }
    standalone_fusion_state=STANDALONE_FUSION_ACTIVE;
}

void standalone_fusion_poll(void) {
    if(standalone_fusion_state!=STANDALONE_FUSION_ACTIVE)return;
    /* Local control supplies the existing lease while the service loop is
     * executing. Preserve the driver's two-second expiry and clock rollback
     * handling; no extra watchdog, target reset, or automatic restart.
     * A stopped/expired driver rejects this call, so even a rejected manual
     * request that already stopped the driver cannot be undone here. */
    if(servo_tracking_keepalive()!=0)
        standalone_fusion_state=STANDALONE_FUSION_STOPPED;
}

void standalone_fusion_command(const uint8_t *payload, unsigned bytes, int accepted) {
    if(!accepted || !payload || !bytes ||
       standalone_fusion_state!=STANDALONE_FUSION_ACTIVE)return;
    switch(payload[0]) {
    case 5:  /* Explicit mode selection. */
    case 6:  /* Freeze/resume capture. */
    case 13: /* Manual horizontal command. */
    case 14: /* Manual vertical command. */
    case 15: /* Stop or explicit PC automatic mode. */
    case 17: /* Legacy ownership command, if the driver accepts it. */
        break;
    case 8:
        if(bytes<2u || payload[1]<2u)return;
        break; /* Manual ROI enters independent visual diagnostics. */
    default:
        return; /* Heartbeat, telemetry and online tuning keep their semantics. */
    }
    standalone_fusion_last_command=payload[0];
    standalone_fusion_state=STANDALONE_FUSION_PC;
}
