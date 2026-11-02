"""Compile an isolated core1 ELF against the existing production BSP."""
from pathlib import Path
import subprocess, sys, hashlib, json, re, os
WS=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(WS/'application/tools'))
from local_tools import arm_tool,vivado_bin
sys.path.insert(0,str(WS/'audio_features/tools'))
from linker import make_linker,check_map
ROOT=WS/'audio_features'
BASE=ROOT.parent/'platform'
def main():
    # Packaged PL overlay has already been verified against its manifest.
    work=Path(__file__).resolve().parent/'build';work.mkdir(parents=True,exist_ok=True)
    linker=make_linker(work)
    gcc=str(arm_tool())
    specs=Path(os.environ.get('XILINX_SPEC',vivado_bin().parent/'data/embeddedsw/scripts/specs/arm/Xilinx.spec'))
    assert specs.is_file()
    bsp=BASE/'bsp_core1';app=BASE/'capture/sdk/core1_audio'
    recording=WS/'application/software'
    flags=['-O2','-std=c11','-ffp-contract=off','-ffunction-sections','-fdata-sections','-mcpu=cortex-a9','-mfpu=vfpv3','-mfloat-abi=hard','-Wall','-Wextra']
    flags += ['-I'+str(p) for p in [recording,recording/'sd_vendor',bsp/'include',BASE/'src',BASE/'runtime/src',BASE/'runtime/generated',BASE/'capture/shared/include',app/'include',ROOT/'software']]
    sources=[p for p in sorted((app/'src').glob('*.c')) if p.name!='model_logmel32.c']
    sources += [BASE/'src/fusion_math.c',BASE/'src/fusion_audio.c',bsp/'libsrc/standalone_v6_8/src/xil_printf.c',ROOT/'software/model_logmel32_pl.c',ROOT/'software/logmel_pl.c']
    sources += [recording/n for n in ('sd_writer.c','sd_disk.c','sd_vendor/ff.c','sd_vendor/ffunicode.c','sd_vendor/xsdps.c','sd_vendor/xsdps_card.c','sd_vendor/xsdps_host.c','sd_vendor/xsdps_options.c')]
    def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[dict(path=str(p),sha256=sha(p)) for p in sources]
    objects=[]
    for i,src in enumerate(sources):
        obj=work/f'{i}_{src.stem}.o'
        with (work/f'{src.stem}.log').open('w') as log:
            subprocess.check_call([gcc]+flags+['-MD','-MF',str(work/f'{i}.d'),'-c',str(src),'-o',str(obj)],stdout=log,stderr=subprocess.STDOUT)
        objects.append(str(obj))
    with (work/'link.log').open('w') as log:
        subprocess.check_call([gcc]+flags+['-specs='+str(specs)]+objects+[
            '-L'+str(bsp/'lib'),'-Wl,--defsym=_STACK_SIZE=0x20000,--defsym=_HEAP_SIZE=0x200000','-Wl,--gc-sections,--build-id=none',
            '-Wl,-T','-Wl,'+str(linker),'-Wl,-Map,'+str(work/'core1.map'),
            '-Wl,--start-group','-lxil','-lm','-lgcc','-lc','-Wl,--end-group','-o',str(work/'core1_logmel.elf')],stdout=log,stderr=subprocess.STDOUT)
    check_map(work/'core1.map')
    dependencies=set()
    for i in range(len(sources)):
        text=(work/f'{i}.d').read_text(encoding='utf8').replace('\\\n',' ')
        for token in re.findall(r'(?:\\[ \t]|[^\s])+',text.split(': ',1)[1]):
            path=Path(token.replace('\\ ',' ').replace('\\\t','\t')).resolve()
            assert path.is_file(),path
            dependencies.add(path)
    links={linker.resolve(),specs.resolve()}
    for found in re.finditer(r'^LOAD (.+)$',(work/'core1.map').read_text(),re.M):
        # GNU ld synthetic map entry is not a filesystem input.
        if found[1].strip()=="linker stubs":continue
        path=Path(found[1].strip().strip('"')).resolve();assert path.is_file();links.add(path)
    for item in inputs:assert sha(Path(item['path']))==item['sha256']
    receipt=dict(compiler=gcc,inputs=inputs,
        dependencies=[dict(path=str(p),sha256=sha(p)) for p in sorted(dependencies)],
        link_inputs=[dict(path=str(p),sha256=sha(p)) for p in sorted(links)],
        elf_sha256=sha(work/'core1_logmel.elf'),project_revision='M51',
        default_capture_samples=96000,model_samples=160000,default_pause_us=5000000,
        runtime_sound_timing=True)
    (work/'compile_inputs.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print('CORE1_LOGMEL_BUILD_PASS')
if __name__=='__main__':main()
