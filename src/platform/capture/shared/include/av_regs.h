#ifndef AX7020_AV_REGS_H
#define AX7020_AV_REGS_H

#define AV_REG_ID                 0x00u
#define AV_REG_VERSION            0x04u
#define AV_REG_BUILD_ID           0x08u
#define AV_REG_CONTROL            0x0Cu
#define AV_REG_STATUS             0x10u
#define AV_REG_MEAN_Y             0x14u
#define AV_REG_DARK_RATIO_Q15     0x18u
#define AV_REG_FRAME_COUNT        0x1Cu
#define AV_REG_VIDEO_DROP_COUNT   0x20u
#define AV_REG_MEL_DROP_COUNT     0x24u
#define AV_REG_ERROR_COUNT        0x28u
#define AV_REG_THRESHOLDS         0x2Cu
#define AV_REG_DARK_RATIO_ENTER   0x30u
#define AV_REG_GAMMA_ADDR         0x34u
#define AV_REG_GAMMA_DATA         0x38u
#define AV_REG_GAMMA_COMMIT       0x3Cu
#define AV_REG_AUDIO_DELAY(ch)    (0x40u + ((ch) * 4u))
#define AV_REG_AUDIO_WEIGHT(ch)   (0x50u + ((ch) * 4u))
#define AV_REG_AUDIO_COMMIT       0x60u
#define AV_REG_COMMIT_STATUS      0x64u
#define AV_REG_MEL_INDEX          0x68u
#define AV_REG_MEL_DATA           0x6Cu
#define AV_REG_MEL_AUDIO_SEQ      0x70u
#define AV_REG_MEL_COMMIT         0x74u

#define AV_REG_ID_VALUE           0x41563031u
#define AV_REG_VERSION_VALUE      0x0001000Au
#define AV_REG_SERVO_PAN          0x78u
#define AV_REG_SERVO_TILT         0x7Cu
#define AV_REG_SERVO_COMMAND      0x80u
#define AV_REG_SERVO_STATUS       0x84u
#define AV_REG_SERVO_ID           0x88u
#define AV_REG_SERVO_COUNT        0x8Cu
#define AV_REG_SERVO_CLOCK        0x90u
#define AV_REG_SERVO_LEFT_FRAMES    0x94u
#define AV_REG_SERVO_RIGHT_FRAMES   0x98u
#define AV_CONTROL_ENHANCE_ENABLE (1u << 0)
#define AV_COMMIT_REQUEST         (1u << 0)

#endif
