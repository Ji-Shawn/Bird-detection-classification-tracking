#include "runtime.h"
#include "ps_math.h"
#include "image_addresses.h"
/* M5.4+: 整网编排 —— 51 层(L01..L51)经 mnet_engine(DW/PW 双模式)+ 10 残差 Add
 *         + L00 STD conv0(PS int8 精确)+ 头部 GAP+Gemm(PS),支持隔离/链式两种模式。
 * 模式:MB[6]=0 隔离(每层吃黄金输入,逐层对拍);MB[6]=1 链式(端到端:上层输出喂下层,
 *      残差加在 block 间,L00 由 PS 实算,头部 GAP+Gemm,最终比 logits)。
 * 帧协议:[w 字][bias 字][像素](ap_ctrl_hs:先写寄存器、最后 ap_start=ENG[0])。
 * 结果表 0x20000100:每层 {total,mismatch,maxd,first};链式附加区 0x20000500 起。
 */
#include <string.h>
#include "xparameters.h"
#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "image_layer_table.h"
#include "image_adds_table.h"
#include "image_head_params.h"
#include "image_weight_offsets.h"
typedef image_layer_t layer_t;
typedef image_add_t add_t;
#define LAYERS IMAGE_LAYERS
#define ADDS IMAGE_ADDS
#define L51_SCALE IMAGE_L51_SCALE
#define L51_ZP IMAGE_L51_ZP
#define VIEW_SCALE IMAGE_VIEW_SCALE
#define VIEW_ZP IMAGE_VIEW_ZP
#define LOG_SCALE IMAGE_LOG_SCALE
#define LOG_ZP IMAGE_LOG_ZP
#define GW_SCALE IMAGE_GW_SCALE
#define GW_ZP IMAGE_GW_ZP
#define GOLD_TOP1 IMAGE_GOLD_TOP1

#ifdef XPAR_AXI_DMA_0_BASEADDR
  #define DMA_BASEADDR  XPAR_AXI_DMA_0_BASEADDR
#else
  #define DMA_BASEADDR  XPAR_XAXIDMA_0_BASEADDR
#endif

#define MB      ((volatile u32 *)0x20000000)
#define RESTAB  ((volatile u32 *)0x20000100)
#define CHRES   ((volatile u32 *)0x20000500)   /* 链式结果区 */
#define ENG     ((volatile u32 *)0x43C20000)
#define DMAREG(o)  (*(volatile u32 *)(0x40410000u + (o)))

/* M5.5 诊断快照:PW 瓦片流程每阶段打点,失败时锁定现场(CHRES[122..131]) */
static void diag_snap(int li, int o0, int stage, int status) {
    volatile u32 *D = (volatile u32 *)(0x20000500u + 4*122);
    D[0] = 0xD1A60000u;
    D[1] = (u32)li; D[2] = (u32)o0; D[3] = (u32)stage; D[4] = (u32)status;
    D[5] = DMAREG(0x04);   /* MM2S_DMASR */
    D[6] = DMAREG(0x34);   /* S2MM_DMASR */
    D[7] = DMAREG(0x00);   /* MM2S_DMACR */
    D[8] = DMAREG(0x30);   /* S2MM_DMACR */
    D[9] = ENG[0];         /* 引擎 CTRL:bit0 ap_start bit2 ap_idle */
    Xil_DCacheFlushRange(0x20000500u + 4*122, 10*4);
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
#define GOLDIN(i) (MAP_GOLDIN[(i)])
#define EXPCT(i) (MAP_EXPCT[(i)])
#define STAGE      0x1E000000u                      /* DW 垫像 staging ≤ 2MB */
#define OUTBUF     0x1E800000u                      /* 引擎输出 scratch ≤ 4MB */
#define FINALB     0x1F000000u                      /* 隔离模式 PW 拼接 ≤ 4MB */
#define CHAIN_A    0x1F400000u                      /* 链式乒乓 A ≤ 4MB */
#define CHAIN_B    0x1F800000u                      /* 链式乒乓 B ≤ 4MB */
#define BLKIN      0x1FC00000u                      /* 残差 block 输入 ≤ 2MB */
#define WGHT(i) (MAP_WGHT[(i)])
#define BIASL(i) (MAP_BIASL[(i)])
#define ADDA(i) (MAP_ADDA[(i)])
#define ADDB(i) (MAP_ADDB[(i)])
#define ADDE(i) (MAP_ADDE[(i)])
#define HEAD_VIEW 0x336844C0u
#define HEAD_LOGQ 0x336849C0u
#define HEAD_GW 0x33684A00u
#define HEAD_GB 0x33697600u

#define DMA_MAXB   16383

static XAxiDma Dma;
static int pw_dma_overlap = 0;  /* MB[7]: magic enables early next MM2S */
static int pw_direct_output = 0; /* MB[7]: single-tile PW S2MM goes to outcur */
static int pw_segment_copy = 0; /* MB[7]: copy each multi-tile channel segment */

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
static u32 calib_khz = 666000;   /* 标定后的 kHz,见 main 开头标定 */

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
    if (t >= 50000000) return -24;
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
            u32 timeout = 0;
            while (XAxiDma_Busy(&Dma, XAXIDMA_DEVICE_TO_DMA)) { fusion_yield();
                if (++timeout >= 50000000) return -17;
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

/* L00 STD conv0(3x3 s2 pad1, 3→32)PS int8 精确实现;已知 ≤5 个 float32 边界噪声像素 */
static int l00_ps(u32 out_addr) {
    const layer_t *L = &LAYERS[0];
    const int H = L->H, W = L->W, HO = H/2, WO = W/2, CO = L->cout;
    const s8 *x = (const s8 *)GOLDIN(0);
    const s8 *w = (const s8 *)WGHT(0);
    const s32 *b = (const s32 *)BIASL(0);
    s8 *o = (s8 *)out_addr;
    Xil_DCacheInvalidateRange(GOLDIN(0), H*W*3);
    conv_spec spec={H,W,3,CO,3,3,2,1,1,HO,WO,1,L->mul,28,L->xzp,L->yzp};
    ps_conv(&spec,x,w,b,o);
    Xil_DCacheFlushRange(out_addr, HO*WO*CO);
    return 0;
}

int image_run(void)
{
    XAxiDma_Config *Cfg;
    int Status;
    int li, ai;

    xil_printf("\r\n== M5.4+ net isolated/chain ==\r\n");
    for (li = 8; li < 16; li++) MB[li] = 0;
    Xil_DCacheFlushRange(0x20000000, 64);

    Cfg = fusion_dma_config();
    if (!Cfg) { MB[0]=0xE0; Xil_DCacheFlushRange(0x20000000,64); return 1; }
    Status = XAxiDma_CfgInitialize(&Dma, Cfg);
    if (Status != XST_SUCCESS || XAxiDma_HasSg(&Dma)) { MB[0]=0xE1; Xil_DCacheFlushRange(0x20000000,64); return 1; }

    ccnt_enable();
    while (MB[0] != 0xC0DE0004) { }
    Xil_DCacheInvalidateRange(0x20000000, 64);   /* 邮箱参数行可能在上次运行的 D-cache 里,读前必刷 */
    int layer_lo = MB[5] >> 16, layer_hi = MB[5] & 0xFFFF;
    if (layer_hi == 0 || layer_hi > 51) { layer_lo = 0; layer_hi = 51; }
    int CHAIN = MB[6];
    pw_dma_overlap = (MB[7] == 0x50495045u || MB[7] == 0x424F5448u || MB[7] == 0x4D454D43u); /* PIPE/BOTH/MEMC */
    pw_direct_output = (MB[7] == 0x44495245u || MB[7] == 0x424F5448u || MB[7] == 0x4D454D43u); /* DIRE/BOTH/MEMC */
    pw_segment_copy = (MB[7] == 0x4D454D43u); /* MEMC */
    CHRES[15] = 0x494D4731u; /* IMG1 outside PW profiling slots */
    CHRES[7] = 0xC0DE0000u | MB[6];
    Xil_DCacheFlushRange(0x20000500, 64);
    {   /* 清结果表 */
        volatile u32 *rt = RESTAB;
        int i2; for (i2 = 0; i2 < 62*4; i2++) rt[i2] = 0xDEADBEEF;
        for (i2 = 16; i2 < 80; i2++) CHRES[i2] = 0xDEADBEEF;   /* [0..15] 保留:标定/头部 */
        Xil_DCacheFlushRange(0x20000100, 62*16 + 0x400 + 80*4);
    }

    u32 chain_in = CHAIN_A, outcur = CHAIN_B;
    /* 残差 block 起点(expand PW 层)与 add 应用点(项目 PW 层) */
    static const int blk_start[10] = {6, 12, 15, 21, 24, 27, 33, 36, 42, 45};
    static const int add_after[10] = {8, 14, 17, 23, 26, 29, 35, 38, 44, 47};

    if (CHAIN) {
        /* L00: PS 实算 → chain_in */
        u32 tq = ccnt();
        l00_ps(chain_in);
        CHRES[10] = ccnt() - tq;          /* L00 PS 耗时 */
    }

    for (li = layer_lo; li <= layer_hi; li++) { fusion_yield();
        const layer_t *L = &LAYERS[li];
        u32 *res = (u32 *)(0x20000100 + li * 16);
        res[0] = res[1] = res[2] = 0; res[3] = 0xFFFFFFFF;
        if (L->typ == 0) { res[3] = 0xFFFFFFFE; continue; }   /* L00: 隔离模式跳过 */

        u32 in_addr = CHAIN ? chain_in : GOLDIN(li);
        u32 tl0 = ccnt();   /* 层起始(含 staging/装载/引擎/散排全程) */

        /* 链式:block 起点保存残差输入 */
        if (CHAIN) {
            int k2;
            for (k2 = 0; k2 < 10; k2++)
                if (li == blk_start[k2]) {
                    memcpy((void *)BLKIN, (void *)in_addr, L->H * L->W * L->cin);
                    Xil_DCacheFlushRange(BLKIN, L->H * L->W * L->cin);
                }
        }

        if (L->typ == 2) {
            /* ---------- DW ---------- */
            int H = L->H, W = L->W, C = L->cin;
            int weng = (L->stride == 2 && (W & 1)) ? W + 1 : W;
            int front = weng + 1, tail = (L->stride == 2) ? 0 : (W + 1);
            int ntot = front + H * weng + tail;
            int wout = (L->stride == 2) ? weng / 2 : W, hout = (L->stride == 2) ? H / 2 : H;
            int skip = (L->stride == 2) ? 0 : 2 * (W + 1);
            int ochunk = DMA_MAXB / C;
            memset((void *)STAGE, 0x80, front * C);
            {
                int r;
                for (r = 0; r < H; r++) {
                    memcpy((void *)(STAGE + (front + r * weng) * C),
                           (void *)(in_addr + r * W * C), W * C);
                    if (weng > W)
                        memset((void *)(STAGE + (front + r * weng + W) * C), 0x80, C);
                }
            }
            if (tail) memset((void *)(STAGE + (front + H * weng) * C), 0x80, tail * C);
            Xil_DCacheFlushRange(STAGE, ntot * C);

            u32 te0 = ccnt();
            Status = eng_cfg(0, L->mul, L->shift, L->xzp, L->yzp, ntot, C, weng, 0,
                    C * 9 / 8, C / 2, L->stride == 2, ochunk);
            if (Status) { res[3] = 0xE0000000u | (-Status); goto rec; }
            Status = push_hdr(WGHT(li), C * 9, BIASL(li), C * 4);
            if (Status) { res[3] = 0xE0000000 | (-Status); goto rec; }
            Status = run_pixels(STAGE, OUTBUF, ntot, hout * wout, C, C,
                                L->stride == 2, ochunk);
            if (Status) { res[3] = 0xE0000000 | (-Status); goto rec; }
            CHRES[70 + li] = ccnt() - te0;   /* 引擎+DMA 段 */
            Xil_DCacheInvalidateRange(OUTBUF, (hout * wout + skip) * C);
            memcpy((void *)outcur, (void *)(OUTBUF + skip * C), hout * wout * C);
            Xil_DCacheFlushRange(outcur, hout * wout * C);
            /* 对拍(隔离=验收,链式=参考性统计) */
            if (unified_validate) Xil_DCacheInvalidateRange(EXPCT(li), hout * wout * C);
            {
                s8 *po = (s8 *)outcur, *pe = (s8 *)EXPCT(li);
                int total = hout * wout * C, i2, bad = 0, maxd = 0, first = -1;
                for (i2 = 0; unified_validate && i2 < total; i2++) {
                    int d = po[i2] - pe[i2];
                    if (d) { if (d < 0) d = -d; if (d > maxd) maxd = d;
                             if (first < 0) first = i2; bad++; }
                }
                res[0] = total; res[1] = bad; res[2] = maxd; res[3] = first;
            }
        } else {
            /* ---------- PW(COUT 瓦片) ---------- */
            int CIN = L->cin, COUT = L->cout, npix = L->H * L->W;
            int tile = 256;
            while (tile > 16 && CIN * tile > 65536) tile -= 16;
            if (tile > COUT) tile = COUT;
            int direct = pw_direct_output && (tile == COUT);
            int o0, total = npix * COUT, bad = 0, maxd = 0, first = -1;
            u32 te0 = ccnt();
            for (o0 = 0; o0 < COUT; o0 += tile) { fusion_yield();
                int ct = (COUT - o0 < tile) ? COUT - o0 : tile;
                u32 s0 = ccnt();
                Status = eng_cfg(1, L->mul, L->shift, L->xzp, L->yzp, npix, CIN, 0, ct,
                        CIN * ct / 8, ct / 2, 0, 0);
                if (Status) { res[3] = 0xE0000000u | (-Status); goto rec; }
                diag_snap(li, o0, 1, 0);
                u32 s1 = ccnt();
                Status = push_hdr(WGHT(li) + o0 * CIN, CIN * ct, BIASL(li) + o0 * 4, ct * 4);
                if (Status) { diag_snap(li, o0, 2, Status); res[3] = 0xE0000000 | (-Status); goto rec; }
                diag_snap(li, o0, 3, 0);
                u32 s2 = ccnt();
                u32 dma_out = direct ? outcur : OUTBUF;
                Status = pw_dma_overlap
                    ? run_pixels_pw_overlap(in_addr, dma_out, npix, CIN, ct)
                    : run_pixels(in_addr, dma_out, npix, npix, CIN, ct, 0, 0);
                if (Status) { diag_snap(li, o0, 4, Status); res[3] = 0xE0000000 | (-Status); goto rec; }
                diag_snap(li, o0, 5, 0);
                u32 s3 = ccnt();
                CHRES[5 + (o0>>8)] = s3 - s2;   /* 第 (o0>>8) 瓦片像素段(0..3 号槽) */
                CHRES[8]  = s1 - s0;   /* 最后一个瓦片的 eng_cfg */
                CHRES[9]  = s2 - s1;   /* 权重装载 */
                CHRES[10] = s3 - s2;   /* 像素段 */
                if (Status) { res[3] = 0xE0000000 | (-Status); goto rec; }
                if (direct) {
                    Xil_DCacheInvalidateRange(outcur, total);
                } else {
                    Xil_DCacheInvalidateRange(OUTBUF, npix * ct);
                    if (pw_segment_copy) {
                        int p;
                        s8 *dst = (s8 *)outcur + o0;
                        s8 *src = (s8 *)OUTBUF;
                        for (p = 0; p < npix; p++) {
                            if (!(p&63)) fusion_yield();
                            memcpy(dst, src, ct);
                            dst += COUT;
                            src += ct;
                        }
                    } else {
                        int p, b;
                        s8 *f = (s8 *)outcur;
                        for (p = 0; p < npix; p++) {
                            if (!(p&63)) fusion_yield();
                            s8 *s = (s8 *)OUTBUF + p * ct;
                            for (b = 0; b < ct; b++) f[p * COUT + o0 + b] = s[b];
                        }
                    }
                }
            }
            CHRES[70 + li] = ccnt() - te0;
            Xil_DCacheFlushRange(outcur, total);
            if (unified_validate) Xil_DCacheInvalidateRange(EXPCT(li), total);
            {
                s8 *po = (s8 *)outcur, *pe = (s8 *)EXPCT(li);
                int i2;
                for (i2 = 0; unified_validate && i2 < total; i2++) {
                    int d = po[i2] - pe[i2];
                    if (d) { if (d < 0) d = -d; if (d > maxd) maxd = d;
                             if (first < 0) first = i2; bad++; }
                }
            }

            res[0] = total; res[1] = bad; res[2] = maxd; res[3] = first;
        }
rec:
        if ((res[3] & 0xF0000000u) == 0xE0000000u) { dma_recover(); return -(int)(res[3] & 0xFFFFu); }
        CHRES[16 + li] = ccnt() - tl0;   /* 层耗时(PMCCNTR 原始拍数) */
        Xil_DCacheFlushRange(0x20000500 + 64, 62*4);
        Xil_DCacheFlushRange((u32)res, 16);

        /* 链式:残差 add + 乒乓换向 */
        if (CHAIN) {
            int k2;
            for (k2 = 0; k2 < 10; k2++)
                if (li == add_after[k2]) {
                    const add_t *A = &ADDS[k2];
                    int n2 = A->n;
                    s8 *a = (s8 *)BLKIN, *b = (s8 *)outcur;
                    Xil_DCacheInvalidateRange(BLKIN, n2);
                    ps_add(n2,a,b,b,A->sa,A->sb,A->sy,A->azp,A->bzp,A->yzp);
                    Xil_DCacheFlushRange(outcur, n2);
                }
            u32 tmp = chain_in; chain_in = outcur; outcur = tmp;
        }
    }

    /* ---------- 10 个残差 Add 隔离对拍(PS float32) ---------- */
    for (ai = 0; unified_validate && ai < 10; ai++) {
        const add_t *A = &ADDS[ai];
        u32 *res = (u32 *)(0x20000100 + (52 + ai) * 16);
        int i2, bad = 0, maxd = 0, first = -1;
        Xil_DCacheInvalidateRange(ADDA(ai), A->n);
        Xil_DCacheInvalidateRange(ADDB(ai), A->n);
        Xil_DCacheInvalidateRange(ADDE(ai), A->n);
        for (i2 = 0; i2 < A->n; i2++) {
            float va = ((float)((s8 *)ADDA(ai))[i2] - A->azp) * A->sa;
            float vb = ((float)((s8 *)ADDB(ai))[i2] - A->bzp) * A->sb;
            int q = sat128(rhe_f((va + vb) / A->sy) + A->yzp);
            int d = q - (int)((s8 *)ADDE(ai))[i2];
            if (d) { if (d < 0) d = -d; if (d > maxd) maxd = d;
                     if (first < 0) first = i2; bad++; }
        }
        res[0] = A->n; res[1] = bad; res[2] = maxd; res[3] = first;
        Xil_DCacheFlushRange((u32)res, 16);
    }

    /* ---------- 链式头部:GAP → view → Gemm → logits ---------- */
    if (CHAIN) {
        u32 th = ccnt();
        s8 *l51 = (s8 *)chain_in;   /* 最后一次换向后,L51 输出在 chain_in */
        int i2, o;
        Xil_DCacheInvalidateRange((u32)l51, 16*1280);
        /* GAP:fp32 mean(与 ORT 一致),Q 到 view */
        static float gacc[1280];
        for (i2 = 0; i2 < 1280; i2++) gacc[i2] = 0.0f;
        for (i2 = 0; i2 < 16; i2++)
            for (o = 0; o < 1280; o++)
                gacc[o] += ((float)l51[i2*1280+o] - L51_ZP) * L51_SCALE;
        static s8 view[1280];
        for (o = 0; o < 1280; o++)
            view[o] = (s8)sat128(rhe_f((gacc[o] / 16.0f) / VIEW_SCALE) + VIEW_ZP);
        /* 对拍 view_q */
        int vbad = 0;
        if (unified_validate) Xil_DCacheInvalidateRange(HEAD_VIEW, 1280);
        for (o = 0; unified_validate && o < 1280; o++) if (view[o] != ((s8 *)HEAD_VIEW)[o]) vbad++;
        /* Gemm:int8 精确累加 + fp32 scale/bias → Q */
        int lbad = 0, got_top1 = 0;
        s8 best = -128;
        Xil_DCacheInvalidateRange(HEAD_GW, 76800);
        Xil_DCacheInvalidateRange(HEAD_GB, 240);
        if (unified_validate) Xil_DCacheInvalidateRange(HEAD_LOGQ, 64);
        for (o = 0; o < 60; o++) {
            int acc = 0;
            for (i2 = 0; i2 < 1280; i2++)
                acc += ((int)view[i2] - VIEW_ZP) * ((int)((s8 *)HEAD_GW)[o*1280+i2] - GW_ZP);
            float fp = (float)acc * (VIEW_SCALE * GW_SCALE) + ((float *)HEAD_GB)[o];
            int q = sat128(rhe_f(fp / LOG_SCALE) + LOG_ZP);
            unified_logits[o] = (int8_t)q;
            if (unified_validate && q != (int)((s8 *)HEAD_LOGQ)[o]) lbad++;
            if (q > best) { best = (s8)q; got_top1 = o; }
        }
        CHRES[0] = 0xC0DE; CHRES[1] = vbad; CHRES[2] = lbad;
        CHRES[3] = got_top1; CHRES[4] = GOLD_TOP1;
        CHRES[11] = ccnt() - th;          /* 头部 PS 耗时 */
        Xil_DCacheFlushRange(0x20000500, 80*4);
    }

    MB[13] = 0x600D;
    Xil_DCacheFlushRange(0x20000000, 0x600);
    xil_printf("M5.4+ done\r\n");
    return 0;
}
