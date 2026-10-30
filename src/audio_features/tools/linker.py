"""Reserve 0x0ff00000..0x10000000 for Core1-only noncacheable Mel DMA."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT.parent/'platform'


def make_linker(work):
    text=(BASE/'build/core1.ld').read_text()
    old='ps7_ddr_0 : ORIGIN = 0x08000000, LENGTH = 0x08000000'
    if text.count(old)!=1:
        raise RuntimeError('Core1 DDR layout changed; review DMA reservation')
    text=text.replace(old,'ps7_ddr_0 : ORIGIN = 0x08000000, LENGTH = 0x07F00000')
    path=work/'core1_logmel.ld'
    path.write_text(text)
    # The reservation lies within the original exclusive Core1 firmware region.
    # Also reject any fixed model asset that might have been added there.
    for asset in json.loads((ROOT.parent/'dist/ax7020_bird_minimal_v1/assets_manifest.json').read_text()):
        a,n=asset['address'],asset['bytes']
        if a < 0x10000000 and 0x0ff00000 < a+n:
            raise RuntimeError('Mel DMA reservation overlaps asset '+asset['name'])
    table=(BASE/'runtime/generated/ssd_table.h').read_text()
    for row in table.split('SSD_LAYERS[98]={',1)[1].split('};',1)[0].splitlines():
        if not row.startswith('{') or '0x' not in row:
            continue
        fields=row.split('},',1)[1].split(',')
        addresses=[int(v.rstrip('u'),16) for v in fields[:8]]
        ninput,noutput,nweights=map(int,fields[8:11])
        for a,n in zip(addresses,[ninput,ninput,ninput,ninput,noutput,noutput,nweights,0]):
            if a and a < 0x10000000 and 0x0ff00000 < a+n:
                raise RuntimeError('Mel DMA reservation overlaps SSD runtime buffer')
    return path


def check_map(path):
    match=re.search(r'^\s*(0x[0-9a-fA-F]+)\s+_end = \.',path.read_text(),re.M)
    if not match or not 0x08000000 < int(match[1],16) <= 0x0ff00000:
        raise RuntimeError('Core1 firmware/heap/stack overlaps Mel DMA reservation')
