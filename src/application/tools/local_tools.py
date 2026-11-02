"""Explicit tool locations first, then PATH; no development-machine paths."""
from pathlib import Path
import os,shutil

def select_dir(variable,executables):
    if os.environ.get(variable):
        directory=Path(os.environ[variable]).resolve()
        if any((directory/name).is_file() for name in executables):return directory
        raise FileNotFoundError(variable+' does not contain '+str(executables))
    for name in executables:
        path=shutil.which(name)
        if path:return Path(path).resolve().parent
    raise FileNotFoundError('Set '+variable+' to the installed tool bin directory')

def vivado_bin():return select_dir('VIVADO_BIN',['vivado.bat','vivado'])
def arm_bin():return select_dir('ARM_GNU_BIN',['arm-none-eabi-gcc.exe','arm-none-eabi-gcc'])

def executable(directory, name):
    """Resolve an installed executable without assuming a Windows suffix."""
    suffixes = ('.exe', '.bat', '') if os.name == 'nt' else ('',)
    for suffix in suffixes:
        path = Path(directory) / (name + suffix)
        if path.is_file():return path
    raise FileNotFoundError('Missing tool '+name+' in '+str(directory))

def arm_tool(name='gcc'):return executable(arm_bin(), 'arm-none-eabi-'+name)
def vivado_tool(name):return executable(vivado_bin(), name)
def debug_tool():
    if os.environ.get('XSCT'):return os.environ['XSCT']
    for name in ('xsct','xsdb','xsct.bat','xsdb.bat'):
        found=shutil.which(name)
        if found:return found
    return str(vivado_bin()/'xsdb.bat')
