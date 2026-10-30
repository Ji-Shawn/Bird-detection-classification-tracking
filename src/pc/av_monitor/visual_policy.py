"""Match the firmware float32 SSD threshold, including its exact boundary."""
import struct
VISUAL_BIRD_MIN_SCORE=struct.unpack('<f',struct.pack('<f',.5))[0]
VISUAL_BIRD_MIN_SCORE_Q6=500000
