# SDK 2018.3 verification

Verified on 2026-09-28 using the HDF exported by Vivado 2018.3 and the SDK
2018.3 XSCT tool. The generated workspace is disposable; all inputs are the
checked-in C, headers and Tcl scripts.

## Reproducible build

```powershell
& 'E:\vivado\SDK\2018.3\bin\xsct.bat' `
  projects/ax7020_av_edge_streaming/sdk/platform/build_all.tcl `
  projects/ax7020_av_edge_streaming/generated/ax7020_av.hdf `
  projects/ax7020_av_edge_streaming/generated/sdk-workspace-four-sd-final3
```

The command builds both BSPs and both applications at `-O2`:

| Image | Link address | text | data | bss | Result |
|---|---:|---:|---:|---:|---|
| `core0_network.elf` | `0x0010_0000` | 120,412 | 3,232 | 2,152,752 | PASS |
| `core1_audio.elf` | `0x0800_0000` | 45,124 | 1,152 | 300,080 | PASS |

`arm-none-eabi-readelf -l` confirms the core-0 LOAD segments remain below
`0x0800_0000`, while the core-1 LOAD segment starts at `0x0800_0000`. The AMP
shared region starts later at `0x1800_0000` and is therefore outside both
linker-owned regions.

The ELF artifacts and mapped LOAD ranges are:

- `core0_network.elf`: 1,041,340 bytes, SHA-256
  `7FA6E874536C71EFA513DF93B4715B13482A7EBCF453C9E46CA0056442152930`,
  mapped within `0x0010_0000..0x0040_D930`.
- `core1_audio.elf`: 323,124 bytes, SHA-256
  `084C35DEA0800FB8074AE720DEAA581070B82743DB3F5FB0F1ADDC9FF62012DE`,
  mapped within `0x0800_0000..0x0805_5470`.

The core-0 BSP contains lwIP 2.0.2 and the PS GEM/UART drivers. Core 0 uses
static address `192.168.1.20/24` and sends to `192.168.1.10`; core 1 owns the
audio DSP path and links the ARM math library. UDP uses a 1,400-byte payload so
the Zynq-7000 GEM/lwIP path does not depend on unsupported jumbo frames.
The Core-1 BSP is compiled with `USE_AMP=1`, so its startup does not reset the
Global Timer or reinitialize shared GIC state.

Core 1 receives four synchronous 24-bit PCM channels at 48 kHz. Each channel
passes through generated Q2.30 high-pass/low-pass filters before bird-activity
detection. Activity gates only the six-pair GCC-PHAT/2-D direction update;
beamforming, Log-Mel/model-tensor production, result publication, and network
transport continue during silence so the existing stream contract is
preserved.

The compiled Core-0 image includes OV5640 SCCB reset/ID/readback, the supplied
sensor initialization table adjusted to 1280×720 RGB565 at 30 fps, VDMA triple
buffer capture, 4×480-sample AXI DMA capture, 10-Hz telemetry and validated
UDP control reception. Core 1 waits for an explicit shared-memory ready magic
before consuming the audio ring.

## Scope of evidence

This verifies HDF/BSP generation, compilation, linking and DDR separation on
the installed Xilinx tools. Physical PHY link, OV5640 SCCB setup, microphone
wiring/polarity, sustained packet loss and acoustic direction accuracy still
require the AX7020 board and are not claimed as bench-verified here.
