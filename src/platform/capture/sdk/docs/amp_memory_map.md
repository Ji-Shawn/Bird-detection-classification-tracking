# Zynq-7020 AMP memory map

| Region | Start | End | Owner / cache policy |
|---|---:|---:|---|
| Core 0 image, stacks, heap | `0x0010_0000` | `0x07FF_FFFF` | CPU0, cached |
| Core 1 image, stacks, heap | `0x0800_0000` | `0x0FFF_FFFF` | CPU1, cached |
| DMA control/reserved | `0x1000_0000` | `0x17FF_FFFF` | CPU0 / DMA |
| AMP descriptors + audio payload | `0x1800_0000` | `0x1803_2FFF` | shared; explicit flush/invalidate |
| AMP ready handshake | `0x1803_F000` | `0x1803_F03F` | Core 0 publishes, Core 1 waits |
| Video triple buffers | `0x1900_0000` | `0x1954_5FFF` | VDMA / CPU0; explicit invalidate |
| Remaining DDR | `0x1954_6000` | `0x3FFF_FFFF` | reserved |

Every shared descriptor is one 64-byte cache line. Producers flush payload,
execute `dmb sy`, flush metadata, then publish `READY`. Consumers claim
`READING`, invalidate metadata and payload, consume, execute `dmb sy`, then
publish `FREE`. Core 0 owns GEM/lwIP and DMA interrupts; Core 1 never calls
lwIP and owns GCC-PHAT, TDOA, denoise and Log-Mel.
