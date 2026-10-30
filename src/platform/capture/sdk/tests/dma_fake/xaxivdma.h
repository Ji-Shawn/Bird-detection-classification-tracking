#pragma once
#include <stdint.h>
typedef uintptr_t UINTPTR;
typedef struct { int unused; } XAxiVdma;
typedef struct { UINTPTR BaseAddress; } XAxiVdma_Config;
typedef struct { unsigned VertSizeInput, HoriSizeInput, Stride, EnableCircularBuf;
    UINTPTR FrameStoreStartAddr[3]; } XAxiVdma_DmaSetup;
#define XST_SUCCESS 0
#define XAXIVDMA_WRITE 2
#define XAXIVDMA_SR_HALTED_MASK 1u
#define XAXIVDMA_SR_ERR_INTERNAL_MASK 0x10u
#define XAXIVDMA_SR_ERR_SLAVE_MASK 0x20u
#define XAXIVDMA_SR_ERR_DECODE_MASK 0x40u
#define XAXIVDMA_SR_ERR_FSZ_LESS_MASK 0x80u
#define XAXIVDMA_SR_ERR_LSZ_LESS_MASK 0x100u
#define XAXIVDMA_SR_ERR_SG_SLV_MASK 0x200u
#define XAXIVDMA_SR_ERR_SG_DEC_MASK 0x400u
#define XAXIVDMA_SR_ERR_FSZ_MORE_MASK 0x800u
#define XAXIVDMA_IXR_ERROR_MASK 0x4000u
extern uint32_t fake_video_status, fake_store, fake_cleared;
static inline uint32_t XAxiVdma_GetStatus(XAxiVdma *v, int d) { return fake_video_status; }
static inline uint32_t XAxiVdma_CurrFrameStore(XAxiVdma *v, int d) { return fake_store; }
static inline int XAxiVdma_ClearDmaChannelErrors(XAxiVdma *v, int d, uint32_t m) {
    /* SDK 2018.3 reads status OR mask, then writes W1C. The test double
     * must also clear other currently latched W1C flags, not just m. */
    fake_cleared |= m; fake_video_status &= ~((fake_video_status | m) & 0xFFF0u); return 0;
}
static inline void XAxiVdma_IntrClear(XAxiVdma *v, uint32_t m, int d) { fake_video_status &= ~m; }
static inline XAxiVdma_Config *XAxiVdma_LookupConfig(int id) { static XAxiVdma_Config c; return &c; }
static inline int XAxiVdma_CfgInitialize(XAxiVdma *v, XAxiVdma_Config *c, UINTPTR b) { return 0; }
static inline int XAxiVdma_DmaConfig(XAxiVdma *v, int d, XAxiVdma_DmaSetup *s) { return 0; }
static inline int XAxiVdma_DmaSetBufferAddr(XAxiVdma *v, int d, UINTPTR *b) { return 0; }
static inline int XAxiVdma_DmaStart(XAxiVdma *v, int d) { return 0; }
