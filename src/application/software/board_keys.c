#include "board_keys.h"
#include "network_service.h"
#include "bird_focus.h"
#include "camera_recovery.h"
#include "av_regs.h"
#include <string.h>

#ifndef AV_REG_BASE
#define AV_REG_BASE 0x43C00000u
#endif

/* PL synchronizes active-low KEY1..4. Never configure the PS GPIO bank. */
#define KEY_INPUT_REG (AV_REG_BASE + 0xA0u)
#define KEY_INPUT_MAGIC 0x4B340000u
#define ENHANCE_MODE_REG (AV_REG_BASE + 0x9Cu)
#define ENHANCE_MODE_MASK 3u
#define DEBOUNCE_US 30000u
#define FOCUS_RETRY_US 20000u
#define MODE_REPLAY_US 1000000u
#define FIXED_FOCUS 280u

struct key_state {
    uint32_t changed;
    unsigned candidate, stable, armed;
};
static struct key_state keys[4];
static unsigned initialized, keys_valid, enhance_mode, enhance_used, enhance_pending;
static unsigned focus_pending, focus_attempted;
static uint32_t last_poll, last_mode, last_focus;
static unsigned recovery_seen,recovery_guard;
static uint32_t recovery_changed_at;
volatile uint32_t board_keys_diag[BOARD_KEYS_DIAG_WORDS];

static int read_keys(uint32_t now,unsigned *pressed) {
    uint32_t value=platform_mmio_read(KEY_INPUT_REG);
    board_keys_diag[BOARD_KEYS_INPUT_REGISTER]=value;
    board_keys_diag[BOARD_KEYS_INPUT_TIME_US]=now;
    if((value & 0xFFFF0000u)!=KEY_INPUT_MAGIC) {
        board_keys_diag[BOARD_KEYS_CAPABILITY_VALID]=0;
        board_keys_diag[BOARD_KEYS_INVALID_READS]++;
        return 0;
    }
    *pressed=(~value) & 15u;
    board_keys_diag[BOARD_KEYS_RAW]=*pressed;
    board_keys_diag[BOARD_KEYS_CAPABILITY_VALID]=1;
    return 1;
}

static void reset_debounce(unsigned pressed,uint32_t now) {
    unsigned i;
    for(i=0;i<4;i++) {
        keys[i].candidate=keys[i].stable=(pressed >> i) & 1u;
        keys[i].armed=!keys[i].stable;
        keys[i].changed=now;
    }
}

static void update_diag(uint32_t now) {
    unsigned i,stable=0,armed=0;
    for(i=0;i<4;i++) {
        stable|=keys[i].stable << i;
        armed|=keys[i].armed << i;
    }
    board_keys_diag[BOARD_KEYS_STABLE]=stable;
    board_keys_diag[BOARD_KEYS_ARMED]=armed;
    board_keys_diag[BOARD_KEYS_ENHANCE_MODE]=enhance_mode;
    board_keys_diag[BOARD_KEYS_FOCUS_PENDING]=focus_pending;
    board_keys_diag[BOARD_KEYS_POLL_TIME_US]=now;
}

static void write_mode(uint32_t now) {
    uint32_t value=platform_mmio_read(ENHANCE_MODE_REG);
    value=(value & ~ENHANCE_MODE_MASK) | enhance_mode;
    platform_mmio_write(ENHANCE_MODE_REG,value);
    value=platform_mmio_read(ENHANCE_MODE_REG) & ENHANCE_MODE_MASK;
    board_keys_diag[BOARD_KEYS_ENHANCE_READBACK]=value;
    board_keys_diag[BOARD_KEYS_MODE_WRITES]++;
    board_keys_diag[BOARD_KEYS_MODE_TIME_US]=now;
    last_mode=now;
    if(value!=enhance_mode)board_keys_diag[BOARD_KEYS_MODE_FAILURES]++;
    else if(enhance_pending) {
        enhance_pending=0;
        board_keys_diag[BOARD_KEYS_ENHANCE_ACCEPTED]++;
    }
}

static void enhance_pressed(unsigned events,uint32_t now) {
    uint32_t control=platform_mmio_read(AV_REG_BASE + AV_REG_CONTROL);
    /* One common mode: a different key replaces the current override.
     * Simultaneous KEY1/KEY2 chooses OFF even if OFF was already active. */
    if((events & 3u)==3u)enhance_mode=1u;
    else if(events & 2u)enhance_mode=(enhance_mode==1u)?0u:1u;
    else enhance_mode=(enhance_mode==2u)?0u:2u;
    enhance_used=enhance_pending=1;
    board_keys_diag[BOARD_KEYS_ENHANCE_REQUESTS]++;
    /* Only a real press enables the master. Periodic replay never does. */
    platform_mmio_write(AV_REG_BASE + AV_REG_CONTROL,
                        control | AV_CONTROL_ENHANCE_ENABLE);
    write_mode(now);
}

static void focus_pressed(unsigned events) {
    /* KEY4 wins simultaneous presses. A newer intent cancels an older retry. */
    focus_pending=(events & 8u)?BOARD_KEYS_FOCUS_AUTO:BOARD_KEYS_FOCUS_MANUAL;
    focus_attempted=0;
    board_keys_diag[BOARD_KEYS_FOCUS_REQUESTS]++;
    if(focus_pending==BOARD_KEYS_FOCUS_MANUAL) {
        board_keys_diag[BOARD_KEYS_MANUAL_REQUESTS]++;
        board_keys_diag[BOARD_KEYS_FOCUS_TARGET]=FIXED_FOCUS;
    } else board_keys_diag[BOARD_KEYS_AUTO_REQUESTS]++;
}

static void focus_try(uint32_t now) {
    int result;
    unsigned intent,action=0,generation=ov5640_recovery_generation();
    if(generation!=recovery_seen) {
        recovery_seen=generation;recovery_guard=1;recovery_changed_at=now;
    }
    if(!focus_pending || (focus_attempted && now-last_focus<FOCUS_RETRY_US))return;
    if(recovery_guard && now-recovery_changed_at<FOCUS_RETRY_US) {
        board_keys_diag[BOARD_KEYS_FOCUS_WAIT_REASON]=4u;return;
    }
    recovery_guard=0;
    intent=focus_pending;
    focus_attempted=1;last_focus=now;
    if(intent==BOARD_KEYS_FOCUS_MANUAL)result=bird_focus_manual(FIXED_FOCUS);
    else {
        uint32_t status[16];
        bird_focus_status(status,(uint64_t)now);
        board_keys_diag[BOARD_KEYS_FOCUS_DRIVER_STATE]=status[2];
        /* The recovery worker can finish before the focus driver reloads its
         * MCU and restores a saved manual target. Wait for that handoff; an
         * early action-1 success must not be overwritten by BOOT_WAIT later. */
        if(ov5640_recovery_busy() || status[2]==1u || status[2]==7u) {
            board_keys_diag[BOARD_KEYS_FOCUS_WAIT_REASON]=
                ov5640_recovery_busy()?1u:(status[2]==1u?2u:3u);
            return;
        }
        /* The existing driver needs action 2 to leave error state 5.
         * Action 1 alone would set enabled without restarting the failed AF. */
        action=status[2]==5u?2u:1u;
        result=bird_focus_control(action);
    }
    board_keys_diag[BOARD_KEYS_FOCUS_WAIT_REASON]=0u;
    board_keys_diag[BOARD_KEYS_FOCUS_ATTEMPTS]++;
    board_keys_diag[BOARD_KEYS_FOCUS_TRY_TIME_US]=now;
    board_keys_diag[BOARD_KEYS_FOCUS_LAST_ACTION]=action;
    board_keys_diag[BOARD_KEYS_FOCUS_RESULT]=(uint32_t)result;
    if(result==0) {
        focus_pending=BOARD_KEYS_FOCUS_NONE;
        board_keys_diag[BOARD_KEYS_FOCUS_ACCEPTED]++;
        board_keys_diag[intent==BOARD_KEYS_FOCUS_MANUAL?
                        BOARD_KEYS_MANUAL_ACCEPTED:BOARD_KEYS_AUTO_ACCEPTED]++;
        board_keys_diag[BOARD_KEYS_FOCUS_ACCEPT_TIME_US]=now;
    } else {
        board_keys_diag[BOARD_KEYS_FOCUS_FAILURES]++;
        if(intent==BOARD_KEYS_FOCUS_MANUAL) {
            /* Stop AF while initialization/recovery rejects the manual target. */
            result=bird_focus_control(0);
            board_keys_diag[BOARD_KEYS_FOCUS_STOP_RESULT]=(uint32_t)result;
        }
    }
    /* Accepted is a driver command, not optical completion. Never periodically
     * reclaim control after a later explicit PC request. */
}

void board_keys_init(uint32_t now) {
    unsigned pressed=0;
    initialized=0;
    memset((void *)board_keys_diag,0,sizeof board_keys_diag);
    keys_valid=read_keys(now,&pressed);
    reset_debounce(pressed,now);
    enhance_mode=enhance_used=enhance_pending=0;
    focus_pending=focus_attempted=0;
    recovery_seen=ov5640_recovery_generation();recovery_guard=0;recovery_changed_at=now;
    last_poll=last_mode=last_focus=now;
    board_keys_diag[BOARD_KEYS_MAGIC]=0x4B455934u; /* KEY4 */
    board_keys_diag[BOARD_KEYS_VERSION]=2u;
    board_keys_diag[BOARD_KEYS_ENHANCE_READBACK]=UINT32_MAX;
    board_keys_diag[BOARD_KEYS_BOOT_HELD]=keys_valid?pressed:UINT32_MAX;
    update_diag(now);
    /* Startup enhancement/AF policy stays unchanged until a real press. */
    initialized=1;
}

void board_keys_poll(uint32_t now) {
    unsigned pressed=0,i,events=0;
    if(!initialized)return;
    board_keys_diag[BOARD_KEYS_POLLS]++;
    if(now<last_poll) {
        /* A reset/wrap cannot finish debounce or synthesize a press. */
        keys_valid=0;
        last_mode=last_focus=now;
        if(recovery_guard)recovery_changed_at=now;
        board_keys_diag[BOARD_KEYS_CLOCK_RESETS]++;
    }
    last_poll=now;
    if(!read_keys(now,&pressed)) {
        /* A missing/wrong PL ABI generates no presses or new commands.
         * Preserve a legal pending request until the paired ABI returns. */
        keys_valid=0;
        update_diag(now);
        return;
    }
    if(!keys_valid) {
        reset_debounce(pressed,now);keys_valid=1;
        update_diag(now);
        return;
    }
    for(i=0;i<4;i++) {
        struct key_state *key=&keys[i];
        unsigned level=(pressed >> i) & 1u;
        if(level!=key->candidate) {
            key->candidate=level;key->changed=now;
        }
        if(key->candidate!=key->stable && now-key->changed>=DEBOUNCE_US) {
            key->stable=key->candidate;
            if(!key->stable)key->armed=1;
            else if(key->armed) {
                key->armed=0;events|=1u << i;
                board_keys_diag[BOARD_KEYS_KEY1_TIME_US+i]=now;
                board_keys_diag[BOARD_KEYS_KEY1_PRESSES+i]++;
            }
        }
    }
    if(events)board_keys_diag[BOARD_KEYS_LAST_EVENTS]=events;
    if(events & 3u)enhance_pressed(events,now);
    if(events & 12u)focus_pressed(events);
    if(enhance_used && now-last_mode>=MODE_REPLAY_US)write_mode(now);
    focus_try(now);
    update_diag(now);
}

