"""Rebuild BOOT from the paired release files or explicitly rebuilt applications."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'build'))
from build_firmware import stage,WORK

def load(path):
    spec=importlib.util.spec_from_file_location('boot_builder',path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--rebuilt',action='store_true');args=p.parse_args()
    sys.path.insert(0,str(ROOT/'build'))
    from verify_package import verify
    verify(firmware_only=args.rebuilt)
    work=stage()
    sys.path.insert(0,str(work/'application/tools'))
    m=load(ROOT/'build/boot/package_sd_base.py')
    m.ROOT=work;m.HERE=ROOT/'build/boot';m.OUT=ROOT/'build/out/boot'
    m.CORE0=ROOT/('build/out/firmware/core0.elf' if args.rebuilt else 'board/firmware/core0.elf')
    m.CORE1=ROOT/('build/out/firmware/core1.elf' if args.rebuilt else 'board/firmware/core1.elf')
    if args.rebuilt:
        for name,elf in [('core0',m.CORE0),('core1',m.CORE1)]:
            rec=json.loads((ROOT/'build/out/firmware'/f'{name}_inputs.json').read_text(encoding='utf8'))
            assert hashlib.sha256(elf.read_bytes()).hexdigest()==rec['elf_sha256'],'Stale rebuilt ELF'
            for item in rec['inputs']+rec.get('dependencies',[]):
                assert hashlib.sha256(Path(item['path']).read_bytes()).hexdigest()==item['sha256'],'Rebuild after source edits'
    m.BIT=ROOT/'board/firmware/system.bit';m.XSA=ROOT/'board/firmware/system.xsa'
    m.ASSETS=ROOT/'data/models';m.FSBL_SOURCE=work/'application/build/fsbl'
    m.OUT.mkdir(parents=True,exist_ok=True)
    fsbl,startup=m.build_fsbl();c1=m.prepare_core1();groups,assets=m.model_groups()
    import struct
    seed=[0x53525032,170000,170000,0,1140,0,0];check=0xa5a55a5a
    for v in seed:check^=v
    ready=bytearray(0x120);struct.pack_into('<III',ready,0,0x4d313157,0x4d323842,0x4d343846)
    struct.pack_into('<8I',ready,0x100,*seed,check);(m.OUT/'ready.bin').write_bytes(ready)
    bif=m.OUT/'boot.bif'
    lines=['the_rom_image:','{',f' [bootloader] {fsbl.as_posix()}']
    lines+=[' '+x.as_posix() for x in [m.BIT,m.CORE0,c1]]
    lines += [f' [load=0x{g["load"]:08x}] {Path(g["path"]).as_posix()}' for g in groups]
    lines += [f' [load=0x30f01000] {(m.OUT/"ready.bin").as_posix()}','}']
    bif.write_text('\n'.join(lines)+'\n',encoding='ascii')
    image=m.OUT/'boot.bin'
    m.run([m.vivado_tool('bootgen'),'-arch','zynq','-image',bif,'-o',image,'-w','on'],m.OUT/'bootgen.log')
    from verify_boot import verify as verify_image
    verified=verify_image(image=image,core0=m.CORE0,core1=m.CORE1,bit=m.BIT,fsbl=fsbl)
    report={'sha256':m.sha(image),'bytes':image.stat().st_size,'rebuilt_applications':args.rebuilt,
            'assets':len(assets),'partitions':8,'fsbl_startup':startup,
            'board_accessed':False,'sd_card_written':False}
    (m.OUT/'build_receipt.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print('BOOT built:',image,'sha256',report['sha256'])
if __name__=='__main__':main()
