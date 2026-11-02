"""Run the packaged offline checks. No board, JTAG or physical SD access."""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/out/checks'


def portable(text: str, compiler: str | None = None) -> str:
    for path, label in ((str(ROOT), '${package_root}'),
                        (ROOT.as_posix(), '${package_root}'),
                        (sys.executable, '${python}')):
        text = text.replace(path, label)
    if compiler:
        text = text.replace(compiler, '${host_cc}')
    return text


def find_compiler(configured: str | None) -> str:
    candidate = configured or os.environ.get('HOST_CC')
    if candidate:
        p = Path(candidate).expanduser()
        resolved = str(p.resolve()) if p.is_file() else shutil.which(candidate)
        if not resolved:
            raise FileNotFoundError('HOST_CC / --host-cc does not identify an existing compiler: ' + candidate)
        return resolved
    found = shutil.which('gcc') or shutil.which('cc')
    if not found:
        raise FileNotFoundError('Install a native GCC-compatible compiler and set HOST_CC, '
                                'or pass --host-cc with its full path. Do not use arm-none-eabi-gcc.')
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host-cc', help='Native GCC-compatible compiler; overrides HOST_CC / PATH')
    parser.add_argument('--skip-package', action='store_true',
                        help='Development only: skip release hashes after edits; report is marked partial')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    inputs = {Path(__file__).resolve()}
    for folder in ('src/pc', 'sim/archive', 'sim/fixtures', 'board/tools',
                   'src/application/software'):
        inputs.update(p for p in (ROOT / folder).rglob('*') if p.is_file()
                      and p.suffix in {'.py', '.c', '.h', '.tcl', '.bin'})
    inputs.update(ROOT / p for p in ('sim/run_tests.py', 'sim/board_tools/run_tests.py',
                                     'sim/compare_inference.py', 'sim/test_inference_comparison.py',
                                     'build/verify_boot.py', 'build/verify_package.py'))
    before = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sorted(inputs)}
    env = os.environ.copy()
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    env['PYTHONIOENCODING'] = 'utf-8'
    # Only the project's tests are needed; unrelated global plugins can change collection.
    env['PYTEST_DISABLE_PLUGIN_AUTOLOAD'] = '1'
    compiler = None
    compiler_error = None
    try:
        compiler = find_compiler(args.host_cc)
        env['HOST_CC'] = compiler
        env['PATH'] = str(Path(compiler).parent) + os.pathsep + env.get('PATH', '')
        version = subprocess.run([compiler, '--version'], capture_output=True, text=True,
                                 encoding='utf8', errors='replace', timeout=15, env=env, check=True)
        compiler_version = version.stdout.splitlines()[0]
    except (OSError, subprocess.SubprocessError, IndexError) as exc:
        compiler_error = str(exc)
        compiler_version = None

    dependencies = {}
    for name in ('numpy', 'Pillow', 'pytest'):
        try:
            dependencies[name] = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            dependencies[name] = 'not installed'
    results = []

    def run(name: str, arguments: list[str], timeout: int = 180) -> None:
        print('CHECK ' + name, flush=True)
        started = time.monotonic()
        command = [sys.executable, '-B', '-X', 'utf8', *arguments]
        stdout = ''
        returncode = None
        try:
            if name == 'native_sd' and compiler_error:
                raise RuntimeError(compiler_error)
            if name == 'pc_pytest' and any(v == 'not installed' for v in dependencies.values()):
                raise RuntimeError('Missing test dependencies. Run: python -m pip install -r src/pc/requirements.txt')
            completed = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, encoding='utf8', errors='replace',
                                       timeout=timeout)
            stdout = completed.stdout
            returncode = completed.returncode
        except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
            stdout += '\n' + str(exc)
        log = OUT / (name + '.txt')
        log.write_text(portable(stdout, compiler), encoding='utf8')
        result = dict(name=name, status='pass' if returncode == 0 else 'fail',
                      returncode=returncode, elapsed_seconds=round(time.monotonic() - started, 3),
                      command=[portable(x, compiler) for x in command],
                      log=log.relative_to(ROOT).as_posix())
        if name == 'comparator_selftest' and returncode == 0:
            match = re.search(r'Ran (\d+) tests? in', stdout)
            if match and int(match.group(1)) > 0:
                result['cases'] = int(match.group(1))
            else:
                result.update(status='fail', count_error='No executed unittest cases reported')
        results.append(result)
        print(name + ': ' + result['status'].upper(), flush=True)
        if returncode != 0:
            print(portable(stdout[-4000:], compiler), flush=True)

    if args.skip_package:
        results.append(dict(name='package', status='skipped', reason='Explicit development --skip-package'))
    else:
        run('package', ['build/verify_package.py'])
    run('boot', ['build/verify_boot.py'])
    run('native_sd', ['sim/run_tests.py'])
    run('comparator_selftest', ['sim/test_inference_comparison.py'])
    junit = OUT / 'pc_pytest.xml'
    junit.unlink(missing_ok=True)
    run('pc_pytest', ['-m', 'pytest', 'src/pc/tests', '-q', '-p', 'no:cacheprovider',
                      '--junitxml=' + str(junit)])
    run('board_tools', ['sim/board_tools/run_tests.py'])
    if junit.is_file():
        try:
            suites = ET.parse(junit).getroot().findall('testsuite')
            counts = {key: sum(int(s.get(key, '0')) for s in suites)
                      for key in ('tests', 'failures', 'errors', 'skipped')}
            next(x for x in results if x['name'] == 'pc_pytest')['junit_counts'] = counts
        except (ET.ParseError, ValueError) as exc:
            next(x for x in results if x['name'] == 'pc_pytest').update(status='fail', junit_error=str(exc))
    for name, path in [('native_sd', ROOT / 'build/out/tests/results.json'),
                       ('board_tools', ROOT / 'build/out/board_tools_tests.json')]:
        item = next(x for x in results if x['name'] == name)
        if item['status'] == 'pass' and path.is_file():
            detail = json.loads(path.read_text(encoding='utf8'))
            item['cases'] = detail['cases']
    changed = [rel for rel, digest in before.items()
               if not (ROOT / rel).is_file() or hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != digest]
    if changed:
        results.append(dict(name='input_stability', status='fail', changed_paths=changed))
    failed = any(x['status'] == 'fail' for x in results)
    status = 'fail' if failed else ('pass_partial' if args.skip_package else 'pass')
    report = dict(status=status, run_utc=dt.datetime.now(dt.timezone.utc).isoformat(),
                  python_version=platform.python_version(), operating_system=platform.platform(),
                  dependencies=dependencies, native_compiler_version=compiler_version,
                  checks=results, board_accessed=False, physical_sd_card_accessed=False,
                  scope='Package/BOOT integrity; native SD policy and FatFs; inference comparator self-tests; PC unit tests; mocked board tools.',
                  limits='Does not compile ARM, synthesize FPGA, measure model accuracy or test physical hardware.',
                  runner_sha256=before[Path(__file__).relative_to(ROOT).as_posix()],
                  input_files_unchanged_during_checks=not changed,
                  source_and_fixture_sha256=before)
    (OUT / 'results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    print('OFFLINE_CHECKS_' + status.upper() + ' build/out/checks/results.json', flush=True)
    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
