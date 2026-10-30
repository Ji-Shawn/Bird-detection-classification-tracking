#include "network_service.h"
#include "camera_recovery.h"

#include "sleep.h"
#include "xgpio.h"
#include "xparameters.h"

#include <stddef.h>
#include <stdint.h>

typedef struct { uint16_t reg; uint8_t value; } ov5640_reg_t;
#include "ov5640_regs.inc"

#define GPIO_SCL   0x01u
#define GPIO_SDA   0x02u
#define GPIO_RESET 0x04u
#define GPIO_PWDN  0x08u
#define GPIO_CONFIG_DONE 0x10u

static XGpio camera_gpio;
static int camera_prepared;
static uint32_t gpio_output;
static uint32_t gpio_direction;
static unsigned recovery_step,recovery_index,recovery_attempts,recovery_generation;
static unsigned recovery_reset_generation,recovery_retries,recovery_focus_valid;
static unsigned recovery_focus_code;
static uint8_t recovery_focus_hi,recovery_focus_lo,recovery_mcu,recovery_vcm_hi,recovery_vcm_lo,recovery_vcm_verify;
static unsigned recovery_vcm_current,recovery_vcm_next,recovery_hard;
static int recovery_result;
static uint64_t recovery_last_poll,recovery_next,recovery_deadline,recovery_started;
volatile uint32_t camera_recovery_diag[12];

static void gpio_commit(void) {
    XGpio_DiscreteWrite(&camera_gpio, 1u, gpio_output);
    XGpio_SetDataDirection(&camera_gpio, 1u, gpio_direction);
}
static void line_drive(uint32_t line, int high) {
    if (high) gpio_output |= line; else gpio_output &= ~line;
    gpio_direction &= ~line;
    gpio_commit();
    usleep(3u);
}
static void line_release(uint32_t line) {
    gpio_direction |= line;
    gpio_commit();
    usleep(3u);
}
static int sda_read(void) { return (XGpio_DiscreteRead(&camera_gpio, 1u) & GPIO_SDA) != 0u; }
static void sccb_start(void) { line_drive(GPIO_SDA, 1); line_drive(GPIO_SCL, 1); line_drive(GPIO_SDA, 0); line_drive(GPIO_SCL, 0); }
static void sccb_stop(void) { line_drive(GPIO_SDA, 0); line_drive(GPIO_SCL, 1); line_drive(GPIO_SDA, 1); }

static int write_byte(uint8_t value) {
    uint32_t bit;
    for (bit = 0; bit < 8u; ++bit) {
        line_drive(GPIO_SDA, (value & 0x80u) != 0u);
        line_drive(GPIO_SCL, 1); line_drive(GPIO_SCL, 0);
        value <<= 1;
    }
    line_release(GPIO_SDA); line_drive(GPIO_SCL, 1);
    bit = (uint32_t)sda_read();
    line_drive(GPIO_SCL, 0);
    return bit == 0u ? 0 : -1;
}
static uint8_t read_byte(void) {
    uint32_t bit; uint8_t value = 0;
    line_release(GPIO_SDA);
    for (bit = 0; bit < 8u; ++bit) {
        line_drive(GPIO_SCL, 1);
        value = (uint8_t)((value << 1) | (uint8_t)sda_read());
        line_drive(GPIO_SCL, 0);
    }
    line_drive(GPIO_SDA, 1); line_drive(GPIO_SCL, 1); line_drive(GPIO_SCL, 0);
    return value;
}
static int reg_write(uint16_t reg, uint8_t value) {
    int status;
    sccb_start();
    /* Each statement is sequenced: bitwise-OR operands alone are not. */
    status = write_byte(0x78u);
    status |= write_byte((uint8_t)(reg >> 8));
    status |= write_byte((uint8_t)reg);
    status |= write_byte(value);
    sccb_stop();
    return status;
}
static int reg_read(uint16_t reg, uint8_t *value) {
    int status;
    sccb_start();
    status = write_byte(0x78u);
    status |= write_byte((uint8_t)(reg >> 8));
    status |= write_byte((uint8_t)reg);
    sccb_stop();
    if (status != 0) return -1;
    sccb_start();
    if (write_byte(0x79u) != 0) { sccb_stop(); return -1; }
    *value = read_byte();
    sccb_stop();
    return 0;
}
/* AF module owns only MCU/VCM registers, never capture format or timing. */
int ov5640_af_read(uint16_t reg,uint8_t *value){return !camera_prepared||recovery_step?-1:reg_read(reg,value);}
int ov5640_af_write(uint16_t reg,uint8_t value){return !camera_prepared||recovery_step?-1:reg_write(reg,value);}
int ov5640_diagnostic_pattern(unsigned mode) {
    uint8_t value,expected=mode==2?0x84u:0u;
    if(mode>2 || recovery_step)return -1;
    /* Sensor-internal bars traverse DVP; PL bars bypass the sensor input.
     * 0x503d/0x84 matches Linux drivers/media/i2c/ov5640.c test_pattern_val. */
    if(reg_write(0x503du,expected) || reg_read(0x503du,&value) || value!=expected)return -1;
    gpio_output=(gpio_output & ~0x20u) | (mode==1?0x20u:0u);
    gpio_direction &= ~0x20u;gpio_commit();return 0;
}
int ov5640_diagnostic_phase(unsigned mode) {
    uint8_t old,value,expected;
    if(mode>1 || recovery_step || reg_read(0x4740u,&old))return -1;
    /* Diagnostic A/B only: preserve HREF/VSYNC, gate PL capture while
     * changing PCLK polarity. No pin remap, synthetic pixels or PLL change. */
    expected=(old & ~0x20u) | (mode==0?0x20u:0u);
    gpio_output &= ~GPIO_CONFIG_DONE;gpio_commit();
    int status=reg_write(0x4740u,expected);
    if(!status)status=reg_read(0x4740u,&value);
    if(!status && value!=expected)status=-1;
    if(status) {
        /* A failed rollback must not resume capture with unknown timing. */
        if(reg_write(0x4740u,old) || reg_read(0x4740u,&value) || value!=old)return -1;
    }
    gpio_output |= GPIO_CONFIG_DONE;gpio_commit();
    return status;
}
static int write_table(const ov5640_reg_t *table, size_t count) {
    size_t i;
    for (i = 0; i < count; ++i) if (reg_write(table[i].reg, table[i].value) != 0) return -1;
    return 0;
}

int ov5640_camera_prepare(void) {
    camera_prepared = 0;
    XGpio_Config *config = XGpio_LookupConfig(XPAR_GPIO_0_DEVICE_ID);
    uint8_t id_high, id_low, value;
    if (config == 0 || XGpio_CfgInitialize(&camera_gpio, config, config->BaseAddress) != XST_SUCCESS) return -1;
    gpio_output = GPIO_PWDN;
    gpio_direction = GPIO_SCL | GPIO_SDA;
    gpio_commit(); usleep(20000u);
    gpio_output &= ~GPIO_PWDN; gpio_commit(); usleep(5000u);
    gpio_output |= GPIO_RESET; gpio_commit(); usleep(20000u);
    if (reg_read(0x300Au, &id_high) || reg_read(0x300Bu, &id_low) ||
        id_high != 0x56u || id_low != 0x40u) return -2;
    if (reg_write(0x3103u, 0x11u) || reg_write(0x3008u, 0x82u)) return -3;
    usleep(10000u);
    if (write_table(ov5640_init_regs, sizeof(ov5640_init_regs) / sizeof(ov5640_init_regs[0])) ||
        write_table(ov5640_1080p15_regs, sizeof(ov5640_1080p15_regs) / sizeof(ov5640_1080p15_regs[0]))) return -4;
    /* Explicitly freeze the network/model contract after the vendor table. */
    if (reg_write(0x3808u, 0x07u) || reg_write(0x3809u, 0x80u) ||
        reg_write(0x380Au, 0x04u) || reg_write(0x380Bu, 0x38u) ||
        /* OmniVision format table: 0x60=BGR high first; 0x61=RGB high first. */
        reg_write(0x4300u, 0x61u) || reg_write(0x501Fu, 0x01u) ||
        /* Paired 1080p servo candidate: live A/B at 0x21 received full frames;
         * 0x01 stopped completing frames. The earlier 720p phase result
         * does not apply to this geometry/implementation. Only PCLK polarity
         * changes; VSYNC/HREF, PLL and RGB565 stay fixed.
         * Evidence: logs/servo_video_phase.json (2026-10-05). */
        reg_write(0x4740u, 0x21u) ||
        reg_write(0x3008u, 0x02u)) return -5;
    if (reg_read(0x3808u, &value) || value != 0x07u) return -6;
    if (reg_read(0x380Bu, &value) || value != 0x38u) return -7;
    if (reg_read(0x4300u, &value) || value != 0x61u) return -8;
    if (reg_read(0x3809u, &value) || value != 0x80u) return -9;
    if (reg_read(0x380Au, &value) || value != 0x04u) return -10;
    if (reg_read(0x501Fu, &value) || value != 0x01u) return -11;
    if (reg_read(0x4740u, &value) || value != 0x21u) return -12;
    if (reg_read(0x3814u, &value) || value != 0x11u) return -13;
    if (reg_read(0x3815u, &value) || value != 0x11u) return -14;
    if (reg_read(0x380Cu, &value) || value != 0x09u) return -15;
    if (reg_read(0x380Du, &value) || value != 0xC4u) return -16;
    if (reg_read(0x380Eu, &value) || value != 0x04u) return -17;
    if (reg_read(0x380Fu, &value) || value != 0x60u) return -18;
    if (reg_read(0x3820u, &value) || value != 0x46u) return -19;
    if (reg_read(0x3821u, &value) || value != 0x00u) return -20;
    /* Let initial sensor frames settle while capture is still held reset.
     * Main arms VDMA before calling camera_start; no startup pixels may fill
     * an unserviced FIFO and latch the enhancement's fail-closed protection. */
    usleep(2000000u);
    camera_prepared = 1;
    return 0;
}
int ov5640_camera_start(void) {
    if (!camera_prepared || recovery_step) return -1;
    gpio_output |= GPIO_CONFIG_DONE;
    gpio_commit();
    return 0;
}
int ov5640_camera_init(void) {
    int rc = ov5640_camera_prepare();
    return rc ? rc : ov5640_camera_start();
}
/* Same contract as camera_prepare, reused one transaction per service call.
 * No alternate PLL, PCLK polarity, geometry, power pin or register table. */
static const ov5640_reg_t recovery_contract[]={
    {0x3808u,0x07u},{0x3809u,0x80u},{0x380au,0x04u},{0x380bu,0x38u},
    {0x4300u,0x61u},{0x501fu,0x01u},{0x4740u,0x21u},{0x3008u,0x02u}
};
static const ov5640_reg_t recovery_verify[]={
    {0x300au,0x56u},{0x300bu,0x40u},
    {0x3808u,0x07u},{0x3809u,0x80u},{0x380au,0x04u},{0x380bu,0x38u},
    {0x4300u,0x61u},{0x501fu,0x01u},{0x4740u,0x21u},
    {0x3814u,0x11u},{0x3815u,0x11u},{0x380cu,0x09u},{0x380du,0xc4u},
    {0x380eu,0x04u},{0x380fu,0x60u},{0x3820u,0x46u},{0x3821u,0x00u}
};
enum {REC_IDLE,REC_STANDBY,REC_RESUME,REC_SETTLE,REC_FOCUS_HI,
      REC_FOCUS_LO,REC_CLOCK,REC_RESET,REC_INIT,REC_GEOMETRY,REC_CONTRACT,
      REC_VERIFY,REC_MCU_READ,REC_MCU_HOLD,REC_VCM_READ_HI,REC_VCM_READ_LO,
      REC_VCM_WRITE_LO,REC_VCM_WRITE_HI,REC_VCM_VERIFY_HI,REC_VCM_VERIFY_LO};
int ov5640_recovery_busy(void){return recovery_step!=REC_IDLE;}
unsigned ov5640_recovery_generation(void){return recovery_generation;}
unsigned ov5640_recovery_reset_generation(void){return recovery_reset_generation;}
int ov5640_recovery_saved_focus(unsigned *code){
    if(!recovery_focus_valid||!code)return 0;
    *code=recovery_focus_code;return 1;
}
void ov5640_recovery_confirm_frame(void){
    if(!recovery_step&&recovery_result==1){recovery_attempts=0;camera_recovery_diag[9]++;}
}
static int recovery_finish(int result){
    recovery_result=result;recovery_step=REC_IDLE;
    if(result==1){camera_prepared=1;gpio_output|=GPIO_CONFIG_DONE;}
    else{camera_prepared=0;gpio_output&=~GPIO_CONFIG_DONE;}
    gpio_commit();camera_recovery_diag[0]=0x43414d52u;
    camera_recovery_diag[1]=0;camera_recovery_diag[2]=(uint32_t)result;
    if(result==1)camera_recovery_diag[7]++;else camera_recovery_diag[8]++;
    return result;
}
int ov5640_recovery_begin(uint64_t now){
    if(recovery_step)return -1;
    /* At most one light and two complete reconfigurations without a frame.
     * A disconnected or damaged sensor must not be reset forever. */
    if(recovery_attempts>=3)return -5;
    if(recovery_started&&now>=recovery_started&&now-recovery_started<2000000u)return -2;
    recovery_started=recovery_last_poll=now;recovery_next=now;
    recovery_deadline=now+6000000u;recovery_result=0;recovery_retries=0;
    recovery_index=0;recovery_generation++;recovery_attempts++;
    gpio_output&=~GPIO_CONFIG_DONE;gpio_commit();
    recovery_hard=recovery_attempts>1;
    recovery_step=recovery_hard?REC_FOCUS_HI:REC_STANDBY;
    camera_recovery_diag[0]=0x43414d52u;camera_recovery_diag[1]=recovery_step;
    camera_recovery_diag[2]=0;camera_recovery_diag[3]=recovery_generation;
    camera_recovery_diag[4]=recovery_attempts;
    return 0;
}
int ov5640_recovery_poll(uint64_t now){
    uint8_t value=0;int rc=0;unsigned old_step=recovery_step,old_index=recovery_index;
    if(!recovery_step)return recovery_result;
    if(now<recovery_last_poll)return recovery_finish(-4);
    recovery_last_poll=now;
    if(now>recovery_deadline)return recovery_finish(-3);
    if(now<recovery_next)return 0;
    recovery_next=now+1000u; /* Exactly one SCCB transaction at most. */
    switch(recovery_step){
    case REC_STANDBY:
        rc=reg_write(0x3008u,0x42u);recovery_step=REC_RESUME;recovery_next=now+20000u;break;
    case REC_RESUME:
        rc=reg_write(0x3008u,0x02u);recovery_step=REC_SETTLE;recovery_next=now+100000u;break;
    case REC_SETTLE:recovery_step=REC_VERIFY;recovery_index=0;break;
    case REC_FOCUS_HI:
        /* Saving the actual code is best effort. SCCB failure is still
         * recorded, and the AF owner retains its last verified target. */
        rc=reg_read(0x3603u,&recovery_focus_hi);recovery_focus_valid=0;
        if(rc){camera_recovery_diag[6]++;rc=0;recovery_focus_hi=0xffu;}
        recovery_step=REC_FOCUS_LO;break;
    case REC_FOCUS_LO:
        rc=reg_read(0x3602u,&value);
        if(!rc&&recovery_focus_hi!=0xffu){recovery_focus_lo=value;recovery_focus_code=((recovery_focus_hi&63u)<<4)|(value>>4);recovery_focus_valid=1;}
        if(rc){camera_recovery_diag[6]++;rc=0;}
        recovery_step=REC_CLOCK;break;
    case REC_CLOCK:rc=reg_write(0x3103u,0x11u);recovery_step=REC_RESET;break;
    case REC_RESET:
        rc=reg_write(0x3008u,0x82u);
        if(!rc){recovery_reset_generation++;camera_recovery_diag[5]=recovery_reset_generation;}
        recovery_step=REC_INIT;recovery_index=0;recovery_next=now+10000u;break;
    case REC_INIT:
        /* The vendor table remains intact. Only keep its AF MCU in reset
         * while its RAM is unavailable; every other 0x3000 bit is retained. */
        rc=reg_write(ov5640_init_regs[recovery_index].reg,(uint8_t)(ov5640_init_regs[recovery_index].value|
            (ov5640_init_regs[recovery_index].reg==0x3000u?0x20u:0u)));
        if(++recovery_index==sizeof ov5640_init_regs/sizeof *ov5640_init_regs){recovery_index=0;recovery_step=REC_GEOMETRY;}break;
    case REC_GEOMETRY:
        rc=reg_write(ov5640_1080p15_regs[recovery_index].reg,ov5640_1080p15_regs[recovery_index].value);
        if(++recovery_index==sizeof ov5640_1080p15_regs/sizeof *ov5640_1080p15_regs){recovery_index=0;recovery_step=REC_CONTRACT;}break;
    case REC_CONTRACT:
        rc=reg_write(recovery_contract[recovery_index].reg,recovery_contract[recovery_index].value);
        if(++recovery_index==sizeof recovery_contract/sizeof *recovery_contract){recovery_index=0;recovery_step=REC_SETTLE;recovery_next=now+100000u;}break;
    case REC_VERIFY:
        rc=reg_read(recovery_verify[recovery_index].reg,&value);
        if(!rc&&value!=recovery_verify[recovery_index].value)rc=-1;
        if(++recovery_index==sizeof recovery_verify/sizeof *recovery_verify){if(!rc){
            if(recovery_hard&&recovery_focus_valid)recovery_step=REC_MCU_READ;
            else return recovery_finish(1);
        }}break;
    /* Restore the lens before releasing capture, while the AF MCU is held.
     * Reloading its firmware later must not leave the first recovered frames
     * at a reset/default focus. Retain the normal <=16-code verified ramp. */
    case REC_MCU_READ:rc=reg_read(0x3000u,&recovery_mcu);recovery_step=REC_MCU_HOLD;break;
    case REC_MCU_HOLD:rc=reg_write(0x3000u,recovery_mcu|0x20u);recovery_step=REC_VCM_READ_HI;break;
    case REC_VCM_READ_HI:rc=reg_read(0x3603u,&recovery_vcm_hi);recovery_step=REC_VCM_READ_LO;break;
    case REC_VCM_READ_LO:
        rc=reg_read(0x3602u,&recovery_vcm_lo);
        recovery_vcm_current=((recovery_vcm_hi&63u)<<4)|(recovery_vcm_lo>>4);
        if(!rc&&recovery_vcm_current==recovery_focus_code)return recovery_finish(1);
        recovery_step=REC_VCM_WRITE_LO;break;
    case REC_VCM_WRITE_LO:
        if(recovery_vcm_current<recovery_focus_code)recovery_vcm_next=recovery_focus_code-recovery_vcm_current>16?recovery_vcm_current+16:recovery_focus_code;
        else recovery_vcm_next=recovery_vcm_current-recovery_focus_code>16?recovery_vcm_current-16:recovery_focus_code;
        rc=reg_write(0x3602u,(uint8_t)((recovery_vcm_next<<4)|(recovery_focus_lo&15u)));
        recovery_step=REC_VCM_WRITE_HI;break;
    case REC_VCM_WRITE_HI:rc=reg_write(0x3603u,(uint8_t)((recovery_focus_hi&0x40u)|(recovery_vcm_next>>4)));recovery_step=REC_VCM_VERIFY_HI;break;
    case REC_VCM_VERIFY_HI:rc=reg_read(0x3603u,&recovery_vcm_verify);recovery_step=REC_VCM_VERIFY_LO;break;
    case REC_VCM_VERIFY_LO:
        rc=reg_read(0x3602u,&value);
        if(!rc&&(recovery_vcm_verify!=((recovery_focus_hi&0x40u)|(recovery_vcm_next>>4))||value!=(uint8_t)((recovery_vcm_next<<4)|(recovery_focus_lo&15u))))rc=-1;
        if(!rc){recovery_vcm_current=recovery_vcm_next;
            if(recovery_vcm_current==recovery_focus_code)return recovery_finish(1);}
        recovery_step=REC_VCM_WRITE_LO;recovery_next=now+20000u;break;
    default:return recovery_finish(-6);
    }
    if(rc){camera_recovery_diag[6]++;if(++recovery_retries>=3)return recovery_finish(-7);
        recovery_step=old_step;recovery_index=old_index;recovery_next=now+20000u;
    }else recovery_retries=0;
    camera_recovery_diag[1]=recovery_step;camera_recovery_diag[10]=recovery_index;
    camera_recovery_diag[11]=recovery_retries;return 0;
}
#ifdef M16_CAMERA_TEST
/* Diagnostic build only: excluded from the delivered production firmware. */
#include "ov5640_diag.inc"
#endif
