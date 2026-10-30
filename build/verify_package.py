"""Verify this portable export without hardware, original folders or old seals."""
from pathlib import Path
import argparse,hashlib,json,re
ROOT=Path(__file__).resolve().parents[1]
EXPECTED={
 'boot.bin':'c04337b3943dcd633f29f63af24005de3d8e3f2d749f85e32b83d6a73b6977d9',
 'core0.elf':'4d2391599eeab5adf9ff38790320aeba958dae3c675687977ba4572c47474e33',
 'core1.elf':'7b44dd4dc2767f44fc105e695ad5c1bc9a46d496f8fd7314663dcf21f5576ca9',
 'system.bit':'e40ca4fa56f394fbb2b5bee504feba79fae2587a027e4db9aeafeeddc4679f26',
}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(firmware_only=False):
    manifest=json.loads((ROOT/'report/package_manifest.json').read_text(encoding='utf8'))
    assert manifest['project']=='m51' and manifest['photo_ssd_minimum']==.95
    for rel,digest in manifest['files'].items():
        if firmware_only and not rel.startswith(('board/firmware/','data/models/')):continue
        p=(ROOT/rel).resolve();assert p.is_relative_to(ROOT) and p.is_file(),('Missing file',rel)
        assert sha(p)==digest,('Package file changed',rel)
    for name,digest in EXPECTED.items():assert sha(ROOT/'board/firmware'/name)==digest,('Wrong release firmware',name)
    assets=ROOT/'data/models'
    rows=json.loads((assets/'assets_manifest.json').read_text(encoding='utf8'));assert len(rows)==391
    for row in rows:
        p=(assets/row['path']).resolve();assert p.is_relative_to(assets) and p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],row['path']
    if not firmware_only:
        for p in ROOT.rglob('*'):
            rel=p.relative_to(ROOT).as_posix()
            if rel.startswith(('build/out/','.git/','.venv/','.pytest_cache/')) or '__pycache__' in p.parts:continue
            assert re.fullmatch(r'[a-z0-9_./-]+',rel),('Nonportable filename',rel)
            if p.is_file():
                assert p.stat().st_size < 50*1024*1024,('Unexpected large file',rel)
                assert p.suffix not in {'.o','.pyc','.jou','.wdb','.dcp'},('Intermediate artifact',rel)
    print('M51_PORTABLE_PACKAGE_PASS',len(manifest['files']),'files',len(rows),'model assets',flush=True)
    return manifest
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--firmware-only',action='store_true');a=p.parse_args();verify(a.firmware_only)
