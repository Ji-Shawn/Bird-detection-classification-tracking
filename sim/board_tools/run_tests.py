"""Offline CLI, filesystem-fixture and Tcl-mock checks; never access hardware."""
from __future__ import annotations

import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import tkinter
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / 'board/tools'
RESULTS = []


def case(name):
    def run(function):
        function()
        RESULTS.append(dict(name=name, passed=True))
        return function
    return run


def load_launcher():
    spec = importlib.util.spec_from_file_location('m51_board_tools_test_launcher', TOOLS / 'launch.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tcl_run(script, cables=None, serial=None, verified=True):
    """Execute the actual Tcl text with every hardware command replaced."""
    interp = tkinter.Tcl()
    log = []
    interp.createcommand('record', lambda *args: log.append(args) or '')
    interp.eval('proc exit {args} {}; rename puts saved_puts; proc puts {args} {record puts {*}$args}; '
                'rename after saved_after; proc after {args} {record after {*}$args}')
    for command in ('connect', 'memmap', 'mwr', 'rst', 'stop', 'fpga', 'dow', 'con', 'disconnect'):
        interp.eval(f'proc {command} {{args}} {{record {command} {{*}}$args}}')
    interp.eval('proc jtag {args} {record jtag {*}$args; '
                'if {[lsearch -exact $args -target-properties]>=0} {return $::mock_cables}; '
                'if {[lindex $args 0] eq "frequency"} {return 1000000}; return ""}')
    interp.eval('proc targets {args} {record targets {*}$args; return ""}')
    interp.eval('proc mrd {args} {record mrd {*}$args; set a [lindex $args 1]; '
                'switch -nocase $a {0x43C00004 {return 0x0001000A} 0x43C00088 {return 0x53525631} '
                '0xf800025c {return 5} 0xf800700c {return 4} default {return 0}}}')
    # Read the actual cable-selection script; only replace the board/asset loads.
    interp.eval('rename source saved_source; proc source {path} {'
                'if {[file tail $path] eq "ps7_init.tcl"} {'
                'proc ::ps7_init {} {record ps7_init}; '
                'proc ::ps7_post_config {} {record ps7_post_config}; return}; '
                'if {[file tail $path] eq "mock_assets.tcl"} {record assets; return}; '
                'uplevel 1 [list saved_source $path]}')
    values = cables if cables is not None else ['MOCK']
    properties = ' '.join('{node_id %d level 0 jtag_cable_serial %s}' % (i + 1, value)
                          for i, value in enumerate(values))
    interp.setvar('mock_cables', properties)
    interp.eval('unset -nocomplain env(M51_CABLE) env(M51_PACKAGE_VERIFIED)')
    if serial is not None:
        interp.setvar('env(M51_CABLE)', serial)
    if verified:
        interp.setvar('env(M51_PACKAGE_VERIFIED)', '1')
    interp.setvar('env(M51_PACKAGE_ROOT)', ROOT.as_posix())
    interp.setvar('env(M51_ASSET_SCRIPT)', 'mock_assets.tcl')
    try:
        interp.eval('source {' + (TOOLS / script).as_posix() + '}')
    except tkinter.TclError as error:
        return log, str(error)
    return log, None


def filesystem_fixture(existing_date=True):
    """A temporary host directory is never treated as an actual removable disk."""
    workspace = tempfile.TemporaryDirectory(prefix='m51_board_fixture_')
    base = Path(workspace.name)
    card = base / 'mock_card'
    photos = card / 'bird_class/mocksp1_1999.12.31'
    photos.mkdir(parents=True)
    (photos / '1.bmp').write_bytes(b'original_photo_fixture')
    (card / 'BOOT.bin').write_bytes(b'old_boot_fixture')
    if existing_date:
        (card / 'bird_class/DATE.TXT').write_bytes(b'1999.12.31\n')
    fw = base / 'board/firmware'
    fw.mkdir(parents=True)
    (fw / 'boot.bin').write_bytes(b'new_boot_fixture')
    template = base / 'board/sd_card/bird_class/date.txt'
    template.parent.mkdir(parents=True)
    template.write_bytes(b'2026.10.29\n')
    launch = load_launcher()
    launch.ROOT = base
    launch.OUT = base / 'build/out/board'
    launch.FIRMWARE = fw
    launch.PUBLISHED = {'boot.bin': launch.sha(fw / 'boot.bin')}
    launch.removable_identity = lambda path: {'fixture': True, 'id': 'mock_card'}
    return workspace, card, launch


def main():
    launch = load_launcher()
    for arguments, code, label in [([], 0, 'default_help_no_hardware'),
        (['--help'], 0, 'explicit_help_no_hardware'),
        (['program'], 2, 'program_requires_explicit_program_flag'),
        (['write-sd'], 2, 'sd_update_requires_target_root')]:
        @case(label)
        def check_cli(arguments=arguments, code=code):
            run = subprocess.run([sys.executable, '-B', '-X', 'utf8', str(TOOLS / 'launch.py'), *arguments],
                                 capture_output=True, text=True, timeout=20)
            assert run.returncode == code, (arguments, run.returncode, run.stderr)

    for data in (b'2026.10.29\n', b'2000.02.29\r\n', b'\xef\xbb\xbf1999.12.31\n'):
        @case('valid_date_' + data.decode('utf-8-sig').strip())
        def check_date(data=data):
            launch.valid_date(data)
    for index, data in enumerate((b'2025.02.29', b'1979.12.31', b'2108.01.01', b'2026-10-29', b'', b'2026.10.29abc')):
        @case('reject_invalid_date_' + str(index))
        def bad_date(data=data):
            try:
                launch.valid_date(data)
            except (ValueError, UnicodeError):
                return
            raise AssertionError('Accepted invalid date')

    @case('tcl_program_preserves_original_boot_sequence')
    def program():
        log, error = tcl_run('program.tcl')
        assert error is None, error
        assert sum(row[0] == 'stop' for row in log) == 4
        assert sum(row[0] == 'con' for row in log) == 2
        names = [row[0] for row in log]
        assert names.index('ps7_init') < names.index('fpga') < names.index('ps7_post_config')
        assert ('mwr', '0x00165808', '10') in log
        assert any(row[0] == 'puts' and 'M51_PROGRAM_COMPLETE=1' in row for row in log)

    @case('tcl_sdcheck_has_reads_and_no_board_mutations')
    def sdcheck():
        log, error = tcl_run('read_only_probe.tcl')
        assert error is None, error
        assert not any(row[0] in ('stop', 'mwr', 'rst', 'fpga', 'dow', 'con') for row in log)
        assert sum(row[:3] == ('mrd', '-value', '0x43c0001c') for row in log) == 2
        assert any(row[0] == 'puts' and 'M51_READ_ONLY_PROBE_COMPLETE=1' in row for row in log)

    for file in ('program.tcl', 'read_only_probe.tcl'):
        @case('unverified_tcl_rejected_before_connect_' + file)
        def unverified(file=file):
            log, error = tcl_run(file, verified=False)
            assert error and not log

    for serials in ([], ['MOCKA', 'MOCKB']):
        @case('ambiguous_cable_count_rejected_' + str(len(serials)))
        def ambiguous(serials=serials):
            log, error = tcl_run('read_only_probe.tcl', cables=serials)
            assert error and 'Expected one JTAG cable' in error
            assert not any(row[0] == 'mrd' for row in log)

    @case('explicit_cable_selects_one_of_two')
    def explicit():
        log, error = tcl_run('read_only_probe.tcl', cables=['MOCKA', 'MOCKB'], serial='MOCKB')
        assert error is None, error
        assert ('jtag', 'targets', '-set', '2') in log

    @case('write_sd_preview_preserves_fixture_files')
    def preview():
        temporary, card, tool = filesystem_fixture()
        try:
            before = {p.relative_to(card).as_posix(): tool.sha(p) for p in card.rglob('*') if p.is_file()}
            with contextlib.redirect_stdout(io.StringIO()):
                assert tool.write_sd(str(card), False) == 0
            assert before == {p.relative_to(card).as_posix(): tool.sha(p) for p in card.rglob('*') if p.is_file()}
            assert not tool.OUT.exists()
        finally:
            temporary.cleanup()

    @case('write_sd_preserves_fixture_photos_and_existing_date')
    def write_existing():
        temporary, card, tool = filesystem_fixture()
        try:
            before = tool.picture_inventory(card)
            with contextlib.redirect_stdout(io.StringIO()):
                tool.write_sd(str(card), True)
            assert tool.picture_inventory(card) == before
            assert (card / 'bird_class/DATE.TXT').read_bytes() == b'1999.12.31\n'
            assert (card / 'BOOT.bin').read_bytes() == b'new_boot_fixture'
            backups = list(tool.OUT.glob('card_backup_*'))
            assert len(backups) == 1
            assert (backups[0] / 'boot.bin').read_bytes() == b'old_boot_fixture'
        finally:
            temporary.cleanup()

    @case('write_sd_adds_missing_fixture_date_only')
    def write_missing():
        temporary, card, tool = filesystem_fixture(existing_date=False)
        try:
            before = tool.picture_inventory(card)
            with contextlib.redirect_stdout(io.StringIO()):
                tool.write_sd(str(card), True)
            after = tool.picture_inventory(card)
            assert set(after) - set(before) == {'bird_class/DATE.TXT'}
            assert all(after[k] == v for k, v in before.items())
            assert (card / 'bird_class/DATE.TXT').read_bytes() == b'2026.10.29\n'
        finally:
            temporary.cleanup()

    @case('write_sd_card_identity_change_does_not_replace_boot')
    def changed_identity():
        temporary, card, tool = filesystem_fixture()
        try:
            calls = iter(({'id': 'first'}, {'id': 'different'}))
            tool.removable_identity = lambda path: next(calls)
            with contextlib.redirect_stdout(io.StringIO()):
                try:
                    tool.write_sd(str(card), True)
                except RuntimeError as error:
                    assert 'identity' in str(error)
                else:
                    raise AssertionError('Identity change was accepted')
            assert (card / 'BOOT.bin').read_bytes() == b'old_boot_fixture'
            assert (card / 'bird_class/DATE.TXT').read_bytes() == b'1999.12.31\n'
        finally:
            temporary.cleanup()

    @case('fixture_writer_refuses_leftover_staging_file')
    def collision():
        temporary, card, tool = filesystem_fixture()
        try:
            (card / 'M51BOOT.TMP').write_bytes(b'leftover_fixture')
            with contextlib.redirect_stdout(io.StringIO()):
                try:
                    tool.write_sd(str(card), True)
                except RuntimeError as error:
                    assert 'already exists' in str(error)
                else:
                    raise AssertionError('Leftover staging file was overwritten')
            assert (card / 'M51BOOT.TMP').read_bytes() == b'leftover_fixture'
            assert (card / 'BOOT.bin').read_bytes() == b'old_boot_fixture'
        finally:
            temporary.cleanup()

    files = [TOOLS / name for name in ('launch.py', 'program.tcl', 'read_only_probe.tcl', 'select_cable.tcl')]
    files.append(Path(__file__).resolve())
    report = dict(status='PASS', cases=len(RESULTS), tests=RESULTS,
        sources={p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
        board_accessed=False, physical_sd_card_read=False, physical_sd_card_written=False,
        scope='Actual portable CLI and Tcl scripts with fully mocked hardware commands; SD writer uses temporary host-directory fixtures with mocked disk identity.',
        limits='Does not validate physical JTAG/USB, removable-disk detection, board cold boot, SD latency or mechanical behavior.')
    output = ROOT / 'build/out/board_tools_tests.json'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('M51_BOARD_TOOLS_OFFLINE_PASS', len(RESULTS), 'cases; no board or physical SD access')


if __name__ == '__main__':
    main()
