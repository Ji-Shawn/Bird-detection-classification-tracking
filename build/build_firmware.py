"""Build the retained M51 generators in an isolated output workspace."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/out'
WORK=OUT/'work'

def stage(fresh=False):
    if fresh and WORK.exists():
        # This is a generated workspace only. Verify its exact resolved parent
        # before removing it, so deleted source files cannot survive a rebuild.
        assert not WORK.is_symlink() and WORK.resolve()==(ROOT/'build/out/work').resolve()
        assert WORK.resolve().parent==OUT.resolve() and WORK.resolve().is_relative_to(ROOT)
        shutil.rmtree(WORK)
    WORK.mkdir(parents=True,exist_ok=True)
    # Source generators retain their reviewed module-relative layout. All writes
    # they perform are confined to build/out/work, never committed sources.
    for p in (ROOT/'src').rglob('*'):
        if p.is_file() and not any(x in {'__pycache__','.pytest_cache'} for x in p.parts):
            q=WORK/p.relative_to(ROOT/'src');q.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,q)
    shutil.copytree(ROOT/'data/models',WORK/'dist/ax7020_bird_minimal_v1',dirs_exist_ok=True)
    return WORK

def run(core):
    work=stage(fresh=True);out=OUT/'firmware';out.mkdir(parents=True,exist_ok=True)
    env=os.environ.copy();env['PYTHONDONTWRITEBYTECODE']='1'
    tasks={
        'core0':('application/tools/build_software.py','application/build/software/core0_hdmi.elf','application/build/software/compile_inputs.json'),
        'core1':('services/core1/build_core1.py','services/core1/build/core1_logmel.elf','services/core1/build/compile_inputs.json'),
    }
    for name in (tasks if core=='both' else [core]):
        script,elf,receipt=tasks[name]
        print('Building '+name,flush=True)
        with (out/(name+'_build.log')).open('w',encoding='utf8') as log:
            result=subprocess.run([sys.executable,'-B','-X','utf8',str(work/script)],cwd=work,env=env,stdout=log,stderr=subprocess.STDOUT)
        if result.returncode:raise RuntimeError((out/(name+'_build.log')).read_text(encoding='utf8',errors='replace')[-10000:])
        dest=out/(name+'.elf');shutil.copyfile(work/elf,dest);shutil.copyfile(work/receipt,out/(name+'_inputs.json'))
        print(name+' built: '+hashlib.sha256(dest.read_bytes()).hexdigest(),flush=True)
    return work

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core',choices=['core0','core1','both'],default='both')
    parser.add_argument('--prepare-only',action='store_true')
    args=parser.parse_args()
    if args.prepare_only:print(stage(fresh=True))
    else:run(args.core)
