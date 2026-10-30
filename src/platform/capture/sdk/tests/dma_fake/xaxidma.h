#pragma once
#include "xaxivdma.h"
typedef struct { UINTPTR RegBase; } XAxiDma;
typedef struct { int unused; } XAxiDma_Config;
#define XAXIDMA_DEVICE_TO_DMA 1
#define XAXIDMA_RX_OFFSET 0x30u
#define XAXIDMA_SR_OFFSET 4u
#define XAXIDMA_BUFFLEN_OFFSET 0x28u
#define XAXIDMA_HALTED_MASK 1u
#define XAXIDMA_IDLE_MASK 2u
#define XAXIDMA_ERR_ALL_MASK 0x770u
#define XAXIDMA_IRQ_ERROR_MASK 0x4000u
#define XAXIDMA_IRQ_ALL_MASK 0x7000u
extern uint32_t fake_audio_status;
static inline uint32_t XAxiDma_ReadReg(UINTPTR b, uint32_t o) {
    return o == XAXIDMA_BUFFLEN_OFFSET ? 7680u : fake_audio_status;
}
static inline void XAxiDma_Reset(XAxiDma *d) {}
static inline int XAxiDma_ResetIsDone(XAxiDma *d) { return 1; }
static inline void XAxiDma_IntrDisable(XAxiDma *d, unsigned m, int r) {}
static inline void XAxiDma_IntrAckIrq(XAxiDma *d, unsigned m, int r) {}
static inline int XAxiDma_SimpleTransfer(XAxiDma *d, UINTPTR p, unsigned n, int r) { return 0; }
static inline XAxiDma_Config *XAxiDma_LookupConfig(int id) { static XAxiDma_Config c; return &c; }
static inline int XAxiDma_CfgInitialize(XAxiDma *d, XAxiDma_Config *c) { return 0; }
static inline int XAxiDma_HasSg(XAxiDma *d) { return 0; }
