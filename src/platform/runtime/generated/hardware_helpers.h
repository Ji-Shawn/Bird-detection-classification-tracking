#ifdef XPAR_AXI_DMA_0_BASEADDR
  #define DMA_BASEADDR  XPAR_AXI_DMA_0_BASEADDR
#else
  #define DMA_BASEADDR  XPAR_XAXIDMA_0_BASEADDR
#endif

#define MB      ((volatile u32 *)0x2F000000)
#define RESTAB  ((volatile u32 *)0x2F000100)
#define CHRES   ((volatile u32 *)0x2F001000)   /* 链式结果区 */
#define ENG     ((volatile u32 *)0x43C20000)
#define DMAREG(o)  (*(volatile u32 *)(0x40410000u + (o)))

/* M5.5 诊断快照:PW 瓦片流程每阶段打点,失败时锁定现场(CHRES[122..131]) */
static void diag_snap(int li, int o0, int stage, int status) {
    volatile u32 *D = (volatile u32 *)(0x2F001000u + 4*240);
    D[0] = 0xD1A60000u;
    D[1] = (u32)li; D[2] = (u32)o0; D[3] = (u32)stage; D[4] = (u32)status;
    D[5] = DMAREG(0x04);   /* MM2S_DMASR */
    D[6] = DMAREG(0x34);   /* S2MM_DMASR */
    D[7] = DMAREG(0x00);   /* MM2S_DMACR */
    D[8] = DMAREG(0x30);   /* S2MM_DMACR */
    D[9] = ENG[0];         /* 引擎 CTRL:bit0 ap_start bit2 ap_idle */
    Xil_DCacheFlushRange(0x2F001000u + 4*240, 10*4);
}

/* mnet_engine 寄存器偏移(xmnet_engine_hw.h) */
#define R_MODE   0x10
#define R_MUL    0x18
#define R_SHIFT  0x20
#define R_XZP    0x28
#define R_YZP    0x30
#define R_N      0x38
#define R_C      0x40
#define R_W      0x48
#define R_COUTT  0x50
#define R_WWORDS 0x58
#define R_BWORDS 0x60
#define R_STR2   0x68
#define R_OCHUNK 0x70

/* DDR 布局(与 drive_net.tcl 严格一致;已做全图重叠检查) */
#define GOLDIN(i)  (0x10000000u + (i)*0x200000u)   /* 2MB/层 → ..0x16800000 */
#define EXPCT(i)   (0x16800000u + (i)*0x200000u)   /* 2MB/层 → ..0x1D000000 */
#define STAGE      0x1E000000u                      /* DW 垫像 staging ≤ 2MB */
#define OUTBUF     0x1E800000u                      /* 引擎输出 scratch ≤ 4MB */
#define FINALB     0x1F000000u                      /* 隔离模式 PW 拼接 ≤ 4MB */
#define CHAIN_A    0x1F400000u                      /* 链式乒乓 A ≤ 4MB */
#define CHAIN_B    0x1F800000u                      /* 链式乒乓 B ≤ 4MB */
#define BLKIN      0x1FC00000u                      /* 残差 block 输入 ≤ 2MB */
#define WGHT(i)    (0x20010000u + (i)*0x100000u)   /* 1MB/层 → ..0x23410000 */
#define BIASL(i)   (0x24000000u + (i)*0x10000u)    /* 64KB/层 */
#define ADDA(i)    (0x25000000u + (i)*0x100000u)
#define ADDB(i)    (0x26000000u + (i)*0x100000u)
#define ADDE(i)    (0x27000000u + (i)*0x100000u)
#define HEAD_VIEW  0x28000000u                      /* view_q 1280B */
#define HEAD_LOGQ  0x28010000u                      /* logits_q 60B */
#define HEAD_GW    0x28100000u                      /* gemm 权重 76800B */
#define HEAD_GB    0x28200000u                      /* gemm bias fp32 240B */

#define DMA_MAXB   16383

static XAxiDma Dma;

/* 恰半向偶(float 域,不依赖 libm):与 ORT QuantizeLinear 的 round-half-even 对齐 */
static inline int rhe_f(float v) {
    int t = (int)v;
    float f = (float)t;
    if (v < 0 && v != f) { f -= 1.0f; t--; }
    float fr = v - f;
    if (fr > 0.5f) { if(!(t&255))fusion_yield(); t++; }
    else if (fr == 0.5f && (t & 1)) { if(!(t&255))fusion_yield(); t++; }
    return t;
}
static inline int sat128(int q) { return q > 127 ? 127 : (q < -128 ? -128 : q); }

/* PMCCNTR 计时(M5.5) */
static inline void ccnt_enable(void) {
    u32 v;
    __asm__ volatile ("mrc p15, 0, %0, c9, c12, 0" : "=r"(v));
    v |= 1;
    __asm__ volatile ("mcr p15, 0, %0, c9, c12, 0" :: "r"(v));
    __asm__ volatile ("mcr p15, 0, %0, c9, c12, 1" :: "r"(0x80000000u));
}
static inline u32 ccnt(void) {
    u32 v; __asm__ volatile ("mrc p15, 0, %0, c9, c13, 0" : "=r"(v)); return v;
}

static int mm2s(u32 addr, u32 bytes) {
    int st = XAxiDma_SimpleTransfer(&Dma, addr, bytes, XAXIDMA_DMA_TO_DEVICE);
    if (st != XST_SUCCESS) return -1;
    u32 t = 0;
    while (XAxiDma_Busy(&Dma, XAXIDMA_DMA_TO_DEVICE) && t < 50000000) { if(!(t&255))fusion_yield(); t++; }
    return (t >= 50000000) ? -2 : 0;
}

static int eng_cfg(int mode, int mul, int shift, int xzp, int yzp,
                    int n, int c, int w, int cout_t, int ww, int bw, int s2, int ochunk) {
    u32 t = 0;
    while (!(ENG[0] & 0x4) && t < 50000000) { if(!(t&255))fusion_yield(); t++; }   /* 等 ap_idle(首帧复位后即闲) */
    if(t >= 50000000) return -24;
    ENG[R_MODE/4]=mode;    ENG[R_MUL/4]=(u32)mul; ENG[R_SHIFT/4]=shift;
    ENG[R_XZP/4]=(u32)xzp; ENG[R_YZP/4]=(u32)yzp; ENG[R_N/4]=n;
    ENG[R_C/4]=c;          ENG[R_W/4]=w;          ENG[R_COUTT/4]=cout_t;
    ENG[R_WWORDS/4]=ww;    ENG[R_BWORDS/4]=bw;    ENG[R_STR2/4]=s2;  ENG[R_OCHUNK/4]=ochunk;
    ENG[0] = 1;
    return 0;            /* ap_start 最后拉:保证所有寄存器先于启动 */
}

static void dma_recover(void) {
    XAxiDma_Reset(&Dma);
    u32 t = 0;
    while (!XAxiDma_ResetIsDone(&Dma) && t < 1000000) { if(!(t&255))fusion_yield(); t++; }
}

/* PW/s1 DMA A/B experiment: queue next MM2S after current MM2S completes,
 * while current S2MM can still be draining. Simple DMA permits one in-flight
 * transaction per direction; output segments must remain in order. */
static int run_pixels_pw_overlap(u32 in_a, u32 out_a, int npix, int in_b, int out_b) {
    int cpx = 256;
    int m = in_b > out_b ? in_b : out_b;
    if (cpx * m > DMA_MAXB) cpx = DMA_MAXB / m;
    if (cpx < 1) return -18;

    int p = 0;
    int cp = npix > cpx ? cpx : npix;
    Xil_DCacheInvalidateRange(out_a, cp*out_b);
    Xil_DCacheFlushRange(in_a, cp*in_b);
    if (XAxiDma_SimpleTransfer(&Dma, out_a, cp*out_b, XAXIDMA_DEVICE_TO_DMA) != XST_SUCCESS)
        return -15;
    if (XAxiDma_SimpleTransfer(&Dma, in_a, cp*in_b, XAXIDMA_DMA_TO_DEVICE) != XST_SUCCESS)
        return -16;

    while (1) { fusion_yield();
        u32 t = 0;
        while (XAxiDma_Busy(&Dma, XAXIDMA_DMA_TO_DEVICE) && t < 50000000) { if(!(t&255))fusion_yield(); t++; }
        if (t >= 50000000) return -17;

        int next = p + cp;
        int next_cp = npix - next > cpx ? cpx : npix - next;
        if (next < npix) {
            Xil_DCacheFlushRange(in_a + next*in_b, next_cp*in_b);
            if (XAxiDma_SimpleTransfer(&Dma, in_a + next*in_b, next_cp*in_b,
                                        XAXIDMA_DMA_TO_DEVICE) != XST_SUCCESS)
                return -18;
        }

        t = 0;
        while (XAxiDma_Busy(&Dma, XAXIDMA_DEVICE_TO_DMA) && t < 50000000) { if(!(t&255))fusion_yield(); t++; }
        if (t >= 50000000) return -17;
        if (next >= npix) break;

        Xil_DCacheInvalidateRange(out_a + next*out_b, next_cp*out_b);
        if (XAxiDma_SimpleTransfer(&Dma, out_a + next*out_b, next_cp*out_b,
                                    XAXIDMA_DEVICE_TO_DMA) != XST_SUCCESS)
            return -19;
        p = next;
        cp = next_cp;
    }
    return 0;
}

/* 像素阶段分块 DMA:s1/PW tlast 透传;s2 引擎自产 tlast(出按 ochunk 分块) */
static int run_pixels(u32 in_a, u32 out_a, int npix_in, int npix_out, int in_b, int out_b,
                      int s2, int ochunk) {
    if (s2) {
        int pc_in = DMA_MAXB / in_b;
        int pc_out = ochunk;
        int pi = 0, po = 0;
        while (po < npix_out) { fusion_yield();
            int cpo = (npix_out - po > pc_out) ? pc_out : (npix_out - po);
            Xil_DCacheInvalidateRange(out_a + po*out_b, cpo*out_b);
            if (XAxiDma_SimpleTransfer(&Dma, out_a + po*out_b, cpo*out_b, XAXIDMA_DEVICE_TO_DMA) != XST_SUCCESS)
                return -11;
            u32 timeout=0;
            while (XAxiDma_Busy(&Dma, XAXIDMA_DEVICE_TO_DMA)) { fusion_yield();
                if(++timeout>=50000000) return -17;
                if (pi < npix_in && !XAxiDma_Busy(&Dma, XAXIDMA_DMA_TO_DEVICE)) {
                    int cpi = (npix_in - pi > pc_in) ? pc_in : (npix_in - pi);
                    Xil_DCacheFlushRange(in_a + pi*in_b, cpi*in_b);
                    if (XAxiDma_SimpleTransfer(&Dma, in_a + pi*in_b, cpi*in_b, XAXIDMA_DMA_TO_DEVICE) != XST_SUCCESS)
                        return -12;
                    pi += cpi;
                }
            }
            po += cpo;
        }
        return 0;
    }
    int cpx = 256;
    int m = in_b > out_b ? in_b : out_b;
    if (cpx * m > DMA_MAXB) cpx = DMA_MAXB / m;
    int p;
    for (p = 0; p < npix_in; p += cpx) { fusion_yield();
        int cp = (npix_in - p > cpx) ? cpx : (npix_in - p);
        Xil_DCacheInvalidateRange(out_a + p*out_b, cp*out_b);
        Xil_DCacheFlushRange(in_a + p*in_b, cp*in_b);
        int st = XAxiDma_SimpleTransfer(&Dma, out_a + p*out_b, cp*out_b, XAXIDMA_DEVICE_TO_DMA);
        if (st != XST_SUCCESS) return -15;
        st = XAxiDma_SimpleTransfer(&Dma, in_a + p*in_b, cp*in_b, XAXIDMA_DMA_TO_DEVICE);
        if (st != XST_SUCCESS) return -16;
        u32 t = 0;
        while (XAxiDma_Busy(&Dma, XAXIDMA_DMA_TO_DEVICE) && t < 50000000) { if(!(t&255))fusion_yield(); t++; }
        while (XAxiDma_Busy(&Dma, XAXIDMA_DEVICE_TO_DMA) && t < 50000000) { if(!(t&255))fusion_yield(); t++; }
        if (t >= 50000000) return -17;
    }
    return 0;
}

static int push_hdr(u32 waddr, int wbytes, u32 baddr, int bbytes) {
    int off = 0;
    while (off < wbytes) {
        int cb = (wbytes - off > DMA_MAXB - 3) ? DMA_MAXB - 3 : wbytes - off;
        cb &= ~7;
        if (mm2s(waddr + off, cb)) return -22;
        off += cb;
    }
    off = 0;
    while (off < bbytes) {
        int cb = (bbytes - off > DMA_MAXB - 3) ? DMA_MAXB - 3 : bbytes - off;
        cb &= ~7;
        if (mm2s(baddr + off, cb)) return -23;
        off += cb;
    }
    return 0;
}

