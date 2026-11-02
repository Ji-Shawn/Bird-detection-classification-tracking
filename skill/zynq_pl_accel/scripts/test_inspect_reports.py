"""Behavioral counterexamples for inspect_reports; synthetic data is not board evidence."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest

from inspect_reports import inspect


HEADER = '''| Tool Version : Vivado v.2023.2 (test fixture)
| Date : synthetic parser test, not an experiment
| Design : unit_fixture
| Device : synthetic
| Design State : test fixture
'''
TIMING = '''checking no_clock (0)
checking unconstrained_internal_endpoints (0)
checking no_input_delay (0)
checking no_output_delay (0)
checking partial_input_delay (0)
checking partial_output_delay (0)
| Design Timing Summary
0.128 0.000 0 100 0.005 0.000 0 100 0.147 0.000 0 100
| Clock Summary
clk_test {0.000 5.000} 10.000 100.000
| Intra Clock Table
'''
UTILIZATION = '''| Instance | Module | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | DSP Blocks |
| unit_fixture | (top) | 10 | 8 | 1 | 1 | 20 | 1 | 2 | 3 |
'''
CDC = '''Severity  Source Clock  Destination Clock  CDC Type  Exceptions  Endpoints  Safe  Unsafe  Unknown  No ASYNC_REG
Info  clk_a  clk_b  Safely Timed  None  1  1  0  0  0
'''
RULES = '''Table of Contents
1. REPORT SUMMARY
2. REPORT DETAILS
1. REPORT SUMMARY
Violations found: 0
2. REPORT DETAILS
'''


class InspectorTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='report_parser_')
        self.directory = Path(self.temporary.name)
        for kind, body in dict(timing=TIMING, utilization=UTILIZATION, cdc=CDC,
                               methodology=RULES, drc=RULES).items():
            (self.directory / ('pl_' + kind + '.rpt')).write_text(HEADER + body, encoding='utf8')

    def tearDown(self):
        self.temporary.cleanup()

    def replace(self, kind, old, new):
        path = self.directory / ('pl_' + kind + '.rpt')
        text = path.read_text(encoding='utf8')
        self.assertIn(old, text)
        path.write_text(text.replace(old, new), encoding='utf8')

    def test_positive_small_hold_is_not_an_invented_failure(self):
        result = inspect(self.directory)
        self.assertEqual(result['status'], 'screen_pass')
        self.assertEqual(result['metrics']['timing']['whs_ns'], 0.005)
        self.assertEqual(result['metrics']['utilization']['dsp'], 3)

    def test_missing_report_is_incomplete(self):
        (self.directory / 'pl_cdc.rpt').unlink()
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_truncated_timing_is_incomplete(self):
        self.replace('timing', '0.128 0.000 0 100 0.005 0.000 0 100 0.147 0.000 0 100', '0.128')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_negative_setup_is_failure(self):
        self.replace('timing', '0.128', '-0.073')
        self.assertEqual(inspect(self.directory)['status'], 'fail')

    def test_nonfinite_value_is_incomplete(self):
        self.replace('timing', '0.128', 'nan')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_no_checked_endpoints_is_incomplete(self):
        self.replace('timing', '0 100', '0 0')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_missing_coverage_is_incomplete(self):
        self.replace('timing', 'checking no_clock (0)', 'not a timing coverage report')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_positive_wns_does_not_hide_missing_constraints(self):
        self.replace('timing', 'checking no_input_delay (0)', 'checking no_input_delay (7)')
        self.assertEqual(inspect(self.directory)['status'], 'review_required')

    def test_cdc_unsafe_requires_review(self):
        self.replace('cdc', 'Info  clk_a  clk_b  Safely Timed  None  1  1  0  0  0',
                     'Critical  clk_a  clk_b  User Ignored  False Path  1  0  1  0  0')
        result = inspect(self.directory)
        self.assertEqual(result['status'], 'review_required')
        self.assertEqual(result['metrics']['cdc']['reported_unsafe_endpoints'], 1)

    def test_no_cdc_rows_is_incomplete(self):
        self.replace('cdc', 'Info  clk_a  clk_b  Safely Timed  None  1  1  0  0  0', '')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_unknown_cdc_row_after_valid_info_is_incomplete(self):
        for unsupported in (
                'Critical Warning  clk_a  clk_b  User Ignored  False Path  1  0  1  0  0',
                '  Unexpected  clk_a  clk_b  User Ignored  False Path  1  0  1  0  0',
                'Critical  clk_a  clk_b  truncated row'):
            with self.subTest(unsupported=unsupported):
                (self.directory / 'pl_cdc.rpt').write_text(HEADER + CDC + unsupported + '\n', encoding='utf8')
                result = inspect(self.directory)
                self.assertEqual(result['status'], 'incomplete')
                self.assertEqual(result['exit_code'], 3)
                self.assertNotIn('cdc', result['metrics'])
                self.assertTrue(any(row['report'] == 'cdc' and 'Unsupported CDC row' in row['detail']
                                    for row in result['findings']))

    def test_unparsed_rule_count_is_incomplete(self):
        self.replace('methodology', 'Violations found: 0', 'Violations found: 1')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_explicit_resource_budget_is_enforced(self):
        self.assertEqual(inspect(self.directory, limits={'dsp': 2})['status'], 'fail')
        self.assertEqual(inspect(self.directory, limits={'dsp': 3})['status'], 'screen_pass')

    def test_mixed_designs_is_incomplete(self):
        self.replace('cdc', 'Design : unit_fixture', 'Design : other_design')
        self.assertEqual(inspect(self.directory)['status'], 'incomplete')

    def test_cli_status_and_report_hash(self):
        output = self.directory / 'review.json'
        script = Path(__file__).with_name('inspect_reports.py')
        command = [sys.executable, '-B', str(script), '--reports', str(self.directory), '--output', str(output)]
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        before = json.loads(output.read_text(encoding='utf8'))
        self.replace('timing', '0.128', '-0.073')
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stderr)
        after = json.loads(output.read_text(encoding='utf8'))
        self.assertNotEqual(before['inputs']['timing']['sha256'], after['inputs']['timing']['sha256'])
        (self.directory / 'pl_drc.rpt').unlink()
        self.assertEqual(subprocess.run(command, capture_output=True).returncode, 3)

    def test_published_reports_are_not_a_clean_signoff(self):
        source = Path(__file__).resolve().parents[3] / 'build/reports'
        if not source.is_dir():
            self.skipTest('Project reports absent; standalone synthetic tests still apply')
        # This is a regression against a specific published fixture, not a
        # resource budget for the project that the skill is copied into.
        snapshot = Path(__file__).resolve().parents[1] / 'examples/published_report_review.json'
        if not snapshot.is_file():
            self.skipTest('Published fixture descriptor absent; synthetic tests still apply')
        expected = json.loads(snapshot.read_text(encoding='utf8'))['inputs']
        for kind, record in expected.items():
            path = source / Path(record['path']).name
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != record['sha256']:
                self.skipTest('Reports are not the published fixture; review this project with inspect_reports.py')
        result = inspect(source)
        self.assertEqual(result['status'], 'review_required')
        self.assertEqual(result['metrics']['timing']['wns_ns'], 0.128)
        self.assertEqual(result['metrics']['utilization']['lut'], 43722)
        self.assertEqual(result['metrics']['utilization']['dsp'], 164)
        self.assertEqual(result['metrics']['cdc']['reported_unsafe_endpoints'], 1)
        self.assertEqual(result['metrics']['cdc']['reported_unknown_endpoints'], 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
