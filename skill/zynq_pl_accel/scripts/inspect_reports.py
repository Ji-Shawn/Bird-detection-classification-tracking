"""Read Vivado English summary reports; never turn missing evidence into a pass.

No Vivado installation or hardware is used. Exit 0: summary screen pass,
2: failure or human review required, 3: incomplete/unsupported input.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import re


class ReportFormatError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ReportFormatError(message)


def metadata(text):
    result = {}
    for key in ('Tool Version', 'Date', 'Design', 'Device', 'Design State'):
        found = re.search(r'^\|\s*' + re.escape(key) + r'\s*:\s*(.+?)\s*$', text, re.M)
        require(found is not None, 'Missing report header: ' + key)
        result[key.lower().replace(' ', '_')] = found.group(1)
    return result


def parse_timing(text):
    head = text.find('| Design Timing Summary')
    tail = text.find('| Clock Summary', head)
    require(head >= 0 and tail > head, 'Missing design timing/clock summary')
    values = None
    for line in text[head:tail].splitlines():
        fields = line.split()
        if len(fields) == 12:
            try:
                values = [float(x) for x in fields]
                break
            except ValueError:
                continue
    require(values is not None, 'Missing twelve-column design timing values')
    require(all(math.isfinite(value) for value in values), 'Non-finite timing value')
    keys = ('wns_ns', 'tns_ns', 'setup_failing_endpoints', 'setup_total_endpoints',
            'whs_ns', 'ths_ns', 'hold_failing_endpoints', 'hold_total_endpoints',
            'wpws_ns', 'tpws_ns', 'pulse_failing_endpoints', 'pulse_total_endpoints')
    result = dict(zip(keys, values))
    for key in keys:
        if key.endswith('endpoints'):
            require(result[key] >= 0 and result[key].is_integer(), 'Invalid endpoint count')
            result[key] = int(result[key])
    for prefix in ('setup', 'hold', 'pulse'):
        require(result[prefix + '_total_endpoints'] > 0, 'No timing endpoints checked: ' + prefix)
        require(result[prefix + '_failing_endpoints'] <= result[prefix + '_total_endpoints'], 'Invalid failing count')
    coverage = {}
    for name, count in re.findall(r'checking (\w+) \((\d+)\)', text):
        require(name not in coverage or coverage[name] == int(count), 'Conflicting check_timing counts: ' + name)
        coverage[name] = int(count)
    for key in ('no_clock', 'unconstrained_internal_endpoints', 'no_input_delay',
                'no_output_delay', 'partial_input_delay', 'partial_output_delay'):
        require(key in coverage, 'Missing coverage count: ' + key)
    result['coverage'] = coverage
    clocks = []
    clock_end = text.find('| Intra Clock Table', tail)
    clock_text = text[tail:clock_end if clock_end >= 0 else len(text)]
    for name, period, frequency in re.findall(r'^\s*(\S+)\s+\{[^}]+\}\s+([\d.]+)\s+([\d.]+)\s*$', clock_text, re.M):
        require(float(period) > 0 and float(frequency) > 0, 'Invalid clock frequency/period')
        clocks.append({'name': name, 'period_ns': float(period), 'frequency_mhz': float(frequency)})
    require(clocks, 'No clock summary entries parsed')
    result['clocks'] = clocks
    return result


def parse_utilization(text):
    require('Total LUTs' in text and 'DSP Blocks' in text, 'Unsupported utilization table; need hierarchical report')
    for line in text.splitlines():
        fields = [x.strip() for x in line.split('|')[1:-1]]
        if len(fields) == 10 and fields[1] == '(top)' and all(x.isdigit() for x in fields[2:]):
            require(not fields[0].startswith('('), 'First top utilization row is not the complete design')
            return dict(instance=fields[0], **dict(zip(
                ('lut', 'logic_lut', 'lutram', 'srl', 'ff', 'ramb36', 'ramb18', 'dsp'), map(int, fields[2:]))))
    raise ReportFormatError('No complete top-level utilization row found')


def parse_cdc(text):
    columns = ['Severity', 'Source Clock', 'Destination Clock', 'CDC Type', 'Exceptions',
               'Endpoints', 'Safe', 'Unsafe', 'Unknown', 'No ASYNC_REG']
    in_table = False
    rows = []
    for number, line in enumerate(text.splitlines(), 1):
        fields = re.split(r'\s{2,}', line.strip())
        if not in_table:
            if fields == columns:
                in_table = True
            continue
        if not line.strip() or re.fullmatch(r'[\s-]+', line):
            continue
        # Do not select only known severity prefixes: an unsupported data row
        # after a valid Info row must not disappear and produce a false pass.
        require(len(fields) == 10 and fields[0] in ('Critical', 'Warning', 'Info')
                and all(x.isdigit() for x in fields[-5:]), 'Unsupported CDC row at line ' + str(number))
        rows.append(dict(zip(('severity', 'source_clock', 'destination_clock', 'cdc_type', 'exceptions'), fields[:5]),
                         **dict(zip(('endpoints', 'safe', 'unsafe', 'unknown', 'no_async_reg'), map(int, fields[-5:]))),
                         line=number))
    require(in_table, 'Missing CDC summary header')
    require(rows, 'No CDC rows parsed; empty/unsupported summaries are not accepted as evidence of no crossings')
    return {'rows': rows, 'critical_rows': sum(x['severity'] == 'Critical' for x in rows),
            'reported_unsafe_endpoints': sum(x['unsafe'] for x in rows),
            'reported_unknown_endpoints': sum(x['unknown'] for x in rows),
            'reported_no_async_reg_endpoints': sum(x['no_async_reg'] for x in rows)}


def parse_rules(text):
    declared = re.search(r'Violations found:\s*(\d+)', text)
    require(declared is not None, 'Missing violations total')
    # Stop before details to avoid counting individual findings twice.
    end = text.find('2. REPORT DETAILS', declared.end())
    summary = text[:end] if end >= 0 else text
    rows = []
    for number, line in enumerate(summary.splitlines(), 1):
        fields = [x.strip() for x in line.split('|')[1:-1]]
        if len(fields) == 4 and re.fullmatch(r'[A-Z0-9]+-\d+', fields[0]):
            require(fields[3].isdigit(), 'Invalid rule count')
            require(fields[1] in ('Error', 'Critical Warning', 'Warning', 'Advisory', 'Info'), 'Unsupported rule severity')
            rows.append(dict(rule=fields[0], severity=fields[1], description=fields[2], count=int(fields[3]), line=number))
    require(sum(x['count'] for x in rows) == int(declared.group(1)), 'Rule table does not match declared violations total')
    return {'violations': int(declared.group(1)), 'rows': rows}


PARSERS = {'timing': parse_timing, 'utilization': parse_utilization, 'cdc': parse_cdc,
           'methodology': parse_rules, 'drc': parse_rules}


def inspect(reports, prefix='pl_', limits=None):
    reports = Path(reports)
    result = {'schema': 'vivado_summary_review_v1', 'scope': 'Summary screening only; no design, topology or hardware signoff',
              'inputs': {}, 'metrics': {}, 'resource_limits': limits or {}, 'findings': []}
    def finding(level, kind, detail, line=None):
        row = {'level': level, 'report': kind, 'detail': detail}
        if line is not None:
            row['line'] = line
        result['findings'].append(row)
    for kind, parse in PARSERS.items():
        path = reports / (prefix + kind + '.rpt')
        # Relative path preserved when the caller supplies a relative directory.
        result['inputs'][kind] = {'path': path.as_posix()}
        try:
            data = path.read_bytes()
            text = data.decode('utf-8-sig').replace('\r\n', '\n').replace('\r', '\n')
            result['inputs'][kind].update(sha256=hashlib.sha256(data).hexdigest(), bytes=len(data), metadata=metadata(text))
            result['metrics'][kind] = parse(text)
        except (OSError, UnicodeError, ReportFormatError) as exc:
            finding('incomplete', kind, str(exc))
    names = {x['metadata']['design'] for x in result['inputs'].values() if 'metadata' in x}
    if len(names) > 1:
        finding('incomplete', 'all', 'Reports describe different designs: ' + ', '.join(sorted(names)))
    timing = result['metrics'].get('timing')
    if timing:
        for key in ('wns_ns', 'tns_ns', 'whs_ns', 'ths_ns', 'wpws_ns', 'tpws_ns'):
            if timing[key] < 0:
                finding('fail', 'timing', key + ' is negative: ' + str(timing[key]))
        for key in ('setup_failing_endpoints', 'hold_failing_endpoints', 'pulse_failing_endpoints'):
            if timing[key]:
                finding('fail', 'timing', key + ': ' + str(timing[key]))
        for key, count in timing['coverage'].items():
            if count:
                finding('review', 'timing', 'check_timing ' + key + ': ' + str(count) + '; inspect the affected objects and constraints')
    util = result['metrics'].get('utilization')
    if util:
        if names and util['instance'] not in names:
            finding('incomplete', 'utilization', 'Utilization instance does not match report design')
        for key, limit in (limits or {}).items():
            if util[key] > limit:
                finding('fail', 'utilization', key + ' ' + str(util[key]) + ' exceeds supplied budget ' + str(limit))
    cdc = result['metrics'].get('cdc')
    if cdc:
        for row in cdc['rows']:
            if row['severity'] in ('Critical', 'Warning') or row['unsafe'] or row['unknown'] or row['no_async_reg']:
                finding('review', 'cdc', row['source_clock'] + ' -> ' + row['destination_clock'] + ': ' +
                        row['severity'] + ', unsafe=' + str(row['unsafe']) + ', unknown=' + str(row['unknown']) +
                        ', no_async_reg=' + str(row['no_async_reg']) + '; requires object-level review', row['line'])
    for kind in ('methodology', 'drc'):
        for row in result['metrics'].get(kind, {}).get('rows', []):
            if row['count']:
                level = 'fail' if row['severity'] == 'Error' else 'review'
                finding(level, kind, row['rule'] + ': ' + row['severity'] + ', count=' + str(row['count']), row['line'])
    levels = {x['level'] for x in result['findings']}
    result['status'] = 'incomplete' if 'incomplete' in levels else 'fail' if 'fail' in levels else 'review_required' if 'review' in levels else 'screen_pass'
    result['exit_code'] = 3 if result['status'] == 'incomplete' else 0 if result['status'] == 'screen_pass' else 2
    return result


def positive_int(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError('Resource budget must be a positive integer')
    return number


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reports', type=Path, required=True, help='Directory containing the five report files')
    parser.add_argument('--prefix', default='pl_', help='Filename prefix; omit for pl_, pass an empty string for none')
    parser.add_argument('--output', type=Path, help='Optional JSON output path; parent directories are created')
    for resource in ('lut', 'ff', 'dsp', 'ramb36', 'ramb18'):
        parser.add_argument('--max-' + resource, type=positive_int)
    args = parser.parse_args()
    limits = {key: getattr(args, 'max_' + key) for key in ('lut', 'ff', 'dsp', 'ramb36', 'ramb18') if getattr(args, 'max_' + key) is not None}
    result = inspect(args.reports, args.prefix, limits)
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if args.output:
        input_paths = {(args.reports / (args.prefix + kind + '.rpt')).resolve() for kind in PARSERS}
        if args.output.resolve() in input_paths:
            parser.error('--output must not overwrite an input report')
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding='utf8')
        print(result['status'] + ': ' + str(len(result['findings'])) + ' findings; output=' + str(args.output))
    else:
        print(rendered, end='')
    return result['exit_code']


if __name__ == '__main__':
    raise SystemExit(main())
