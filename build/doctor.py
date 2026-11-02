"""Read-only environment checks. Does not install tools or access a board."""
from pathlib import Path
import argparse, importlib, json, os, platform, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'src/application/tools'))
from local_tools import arm_tool, vivado_tool, vivado_bin

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', choices=['pc', 'offline', 'arm', 'pl'], default='pc')
    parser.add_argument('--host-cc', help='Native GCC executable; also accepts HOST_CC')
    args = parser.parse_args()
    checks = []
    def check(name, operation):
        try:
            detail = operation()
            checks.append(dict(name=name, status='pass', detail=detail))
        except Exception as error:
            checks.append(dict(name=name, status='fail', detail=str(error)))
    def require(condition, message):
        if not condition:raise RuntimeError(message)
        return message
    def version(command):
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        if result.returncode:raise RuntimeError((result.stderr or result.stdout)[-1500:])
        return result.stdout.splitlines()[0]
    check('python', lambda: require(sys.version_info >= (3, 10), sys.version.split()[0]+'; requires >=3.10'))
    check('project_path', lambda: require(ROOT.as_posix().isascii() and ' ' not in str(ROOT), 'Use a short ASCII path without spaces: '+str(ROOT)))
    if args.profile in ('pc', 'offline'):
        for name in ('numpy', 'PIL', 'tkinter') + (('pytest',) if args.profile=='offline' else ()):
            check(name, lambda name=name: getattr(importlib.import_module(name), '__version__', 'import ok'))
        check('tcl', lambda: importlib.import_module('tkinter').Tcl().eval('info patchlevel'))
    if args.profile=='offline':
        cc=args.host_cc or os.environ.get('HOST_CC') or shutil.which('gcc')
        check('native_compiler', lambda: version([cc, '--version']) if cc else require(False,'Set HOST_CC to native gcc; ARM GCC cannot run host tests'))
        check('compiler_target', lambda: require('arm' not in version([cc, '-dumpmachine']).lower(), 'Native compiler target confirmed') if cc else require(False, 'Native compiler missing'))
    if args.profile=='arm':
        check('arm_compiler', lambda: version([str(arm_tool()), '--version']))
        check('arm_nm', lambda: str(arm_tool('nm')))
        check('arm_objcopy', lambda: str(arm_tool('objcopy')))
        check('bootgen', lambda: str(vivado_tool('bootgen')))
        check('xilinx_spec', lambda: require(Path(os.environ.get('XILINX_SPEC', vivado_bin().parent/'data/embeddedsw/scripts/specs/arm/Xilinx.spec')).is_file(), 'Xilinx.spec exists'))
        check('fsbl_handoff', lambda: require((vivado_bin().parent/'data/embeddedsw/lib/sw_apps/zynq_fsbl/src/fsbl_handoff.S').is_file(), 'Vivado embeddedsw FSBL source exists'))
    if args.profile=='pl':
        check('vivado', lambda: str(vivado_tool('vivado')))
        check('pl_entry', lambda: require((ROOT/'build/pl/build_pl.tcl').is_file(), 'PL entry exists; license and full build are checked during Vivado execution'))
    status='pass' if all(x['status']=='pass' for x in checks) else 'fail'
    print(json.dumps(dict(profile=args.profile, status=status, platform=platform.system(), python=sys.executable, checks=checks), indent=2))
    return 0 if status=='pass' else 1

if __name__=='__main__':raise SystemExit(main())
