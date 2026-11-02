from pathlib import Path
import subprocess,sys,re,os,json,hashlib
ROOT=Path(os.environ.get('M29_SOURCE_ROOT',Path(__file__).resolve().parents[2]))/'detector_preprocess';BASE=ROOT.parent/'platform'
mode=sys.argv[1] if len(sys.argv)>1 else 'app';work=Path(os.environ.get('SSD_BUILD_DIR',ROOT/'build'/('software' if mode=='app' else 'board_test')));work.mkdir(parents=True,exist_ok=True)
text=(BASE/'src/fusion_math.c').read_text()
text=text.replace('int fusion_ssd_input(', 'int fusion_ssd_input_reference(',1)
if mode=='app':
    text+='\n#include "ssd_preprocess_pl.h"\nint fusion_ssd_input(const uint16_t *p,int w,int h,int8_t *ssd) {\n int rc=ssd_preprocess_pl(p,w,h,ssd);\n if(rc==0)return 0;\n if(rc < -1)return rc;\n return fusion_ssd_input_reference(p,w,h,ssd);\n}\n'
else:
    text+='\nint fusion_ssd_input(const uint16_t *p,int w,int h,int8_t *ssd){return fusion_ssd_input_reference(p,w,h,ssd);}\n'
(work/'fusion_math_overlay.c').write_text(text)
bsp=BASE/'bsp_core0';app=BASE/'capture/sdk/core0_network'
sys.path.insert(0,str(ROOT.parent/'application/tools'))
from local_tools import arm_tool,vivado_bin
gcc=str(arm_tool())
spec=Path(os.environ.get('XILINX_SPEC',vivado_bin().parent/'data/embeddedsw/scripts/specs/arm/Xilinx.spec'))
if not spec.is_file():raise FileNotFoundError('Set XILINX_SPEC to the installed Cortex-A9 Xilinx.spec: '+str(spec))
flags=['-O2','-std=c11','-ffp-contract=off','-ffunction-sections','-fdata-sections','-mcpu=cortex-a9','-mfpu=vfpv3','-mfloat-abi=hard','-Wall','-Wextra']
flags+=['-I'+str(p) for p in [bsp/'include',BASE/'src',BASE/'runtime/src',BASE/'runtime/generated',BASE/'capture/shared/include',app/'include',ROOT/'software']]
sources=[work/'fusion_math_overlay.c',ROOT/'software/ssd_preprocess_pl.c',ROOT/'software/ssd_rounding.c',bsp/'libsrc/standalone_v6_8/src/xil_printf.c']
libs=[]
if mode=='app':
    sources+=sorted((app/'src').glob('*.c'))+[BASE/'src/fusion_service.c',BASE/'capture/shared/protocol/av_protocol.c',BASE/'runtime/src/ps_math_optimized.c']
    sources+=[BASE/'runtime/generated'/f'{n}.c' for n in ['audio','image','ssd']];libs=['-llwip4']
else:
    sources+=[ROOT/'software/board_test.c',ROOT.parent/'audio_features/software/board_timer.c']
    flags+=['-DXTime_GetTime=logmel_test_get_time']
sources += [bsp/'libsrc/lwip202_v1_2/src/lwip-2.0.2/src/core/mem.c']
objects=[];compiled_inputs=[]
for i,src in enumerate(sources):
    if src.name in ("stream_scheduler.c","control.c","fusion_service.c","udp_stream.c","visual_tracker.c","dma_service.c"):src=ROOT.parent/'services/core0'/src.name
    obj=work/f'{i}.o';objects.append(str(obj))
    compiled_inputs.append({'path':str(src),'sha256':hashlib.sha256(src.read_bytes()).hexdigest()})
    obj.unlink(missing_ok=True) # Never mistake an old object for this build.
    extra=['-mfpu=neon'] if src.name in ('ps_math_optimized.c','visual_tracker.c') else []
    if src.name=='mem.c': extra += ['-DLWIP_ALLOW_MEM_FREE_FROM_OTHER_CONTEXT=1']
    with (work/f'compile_{i}.log').open('w') as log:
        rc=subprocess.call([gcc]+flags+extra+['-c',str(src),'-o',str(obj)],stdout=log,stderr=subprocess.STDOUT)
    if rc or not obj.is_file():raise RuntimeError((work/f'compile_{i}.log').read_text())
elf=work/('core0_ssd_pl.elf' if mode=='app' else 'ssd_test.elf')
elf.unlink(missing_ok=True)
with (work/'link.log').open('w') as log:
    rc=subprocess.call([gcc]+flags+['-specs='+str(spec)]+objects+[
     '-L'+str(bsp/'lib'),'-Wl,--build-id=none','-Wl,--defsym=_STACK_SIZE=0x20000,--defsym=_HEAP_SIZE=0x200000','-Wl,--gc-sections','-Wl,-T','-Wl,'+str(BASE/'build/core0.ld'),'-Wl,-Map,'+str(work/'app.map'),'-Wl,--start-group']+libs+['-lxil','-lm','-lgcc','-lc','-Wl,--end-group','-o',str(elf)],stdout=log,stderr=subprocess.STDOUT)
if rc or not elf.is_file() or elf.read_bytes()[:4]!=b'\x7fELF':raise RuntimeError((work/'link.log').read_text())
if mode!='app':
    nm=subprocess.check_output([str(arm_tool('nm')),str(elf)],text=True)
    addr=[s.split()[0] for s in nm.splitlines() if s.endswith(' ssd_test_result')];assert len(addr)==1
    (work/'result_address.txt').write_text('0x'+addr[0])
print('SSD_SOFTWARE_BUILD_PASS '+str(elf))
(work/'compile_inputs.json').write_text(json.dumps({'inputs':compiled_inputs,'flags':flags,
    'compiler':gcc,'compiler_version':subprocess.check_output([gcc,'--version'],text=True).splitlines()[0],
    'elf_sha256':hashlib.sha256(elf.read_bytes()).hexdigest()},indent=2),encoding='utf8')
