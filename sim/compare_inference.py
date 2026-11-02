"""Compare independently captured inference results with the packaged samples."""
from pathlib import Path
import argparse, hashlib, json, math

ROOT=Path(__file__).resolve().parents[1]
SAMPLES=ROOT/'data/models/samples'
NAMES={'1':'audio.bin','2':'image.bin','3':'ssd.bin'}
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def finite(value):
    return isinstance(value,(int,float)) and not isinstance(value,bool) and math.isfinite(value)

def compare(expected, actual, logit_tol=0, box_tol=0.001, score_tol=0.00001):
    """Numeric-only comparison. Does not assert that a hardware run occurred."""
    if not all(finite(x) and x>=0 for x in (logit_tol,box_tol,score_tol)):
        raise ValueError('Tolerances must be finite and nonnegative')
    if set(actual)!=set(NAMES) or set(expected)!=set(NAMES):
        raise ValueError('Exactly models 1 (audio), 2 (image), 3 (SSD) are required')
    results={}
    for key in ('1','2'):
        e=expected[key];a=actual[key]
        if set(a)!={'logits','top1'}:raise ValueError(key+': expected logits and top1 only')
        logits=a['logits']
        if not isinstance(logits,list) or len(logits)!=60 or not all(isinstance(x,int) and not isinstance(x,bool) and -128<=x<=127 for x in logits):
            raise ValueError(key+': logits must be exactly 60 int8 values; UI probabilities are not logits')
        if type(a['top1']) is not int or not 0<=a['top1']<60:raise ValueError('Invalid top1')
        if a['top1']!=max(range(60),key=lambda i:logits[i]):raise ValueError('top1 disagrees with logits (first index breaks ties)')
        errors=[abs(x-y) for x,y in zip(e['logits'],logits)]
        results[key]=dict(pass_numeric=max(errors)<=logit_tol and a['top1']==e['top1'],
            max_abs_error=max(errors),mismatches=sum(x>logit_tol for x in errors),top1=a['top1'],expected_top1=e['top1'])
    def detections(row):
        if set(row)!={'detections'} or not isinstance(row['detections'],list):raise ValueError('SSD detections list required')
        found={}
        for d in row['detections']:
            if set(d)!={'anchor','box','score'}:raise ValueError('Each detection requires anchor, box, score')
            if type(d['anchor']) is not int or d['anchor']<0 or d['anchor'] in found:raise ValueError('Invalid or duplicate anchor')
            if not isinstance(d['box'],list) or len(d['box'])!=4 or not all(finite(x) for x in d['box']):raise ValueError('Invalid box')
            if not finite(d['score']) or not 0<=d['score']<=1:raise ValueError('Invalid score')
            if d['box'][2]<d['box'][0] or d['box'][3]<d['box'][1]:raise ValueError('Invalid box ordering')
            found[d['anchor']]=d
        return found
    e=detections(expected['3']);a=detections(actual['3']);rows=[]
    for anchor in sorted(set(e)&set(a)):
        box_error=max(abs(x-y) for x,y in zip(e[anchor]['box'],a[anchor]['box']))
        score_error=abs(e[anchor]['score']-a[anchor]['score'])
        rows.append(dict(anchor=anchor,box_max_abs_error=box_error,score_abs_error=score_error,
            pass_numeric=box_error<=box_tol and score_error<=score_tol))
    results['3']=dict(pass_numeric=set(e)==set(a) and all(x['pass_numeric'] for x in rows),
        missing_anchors=sorted(set(e)-set(a)),unexpected_anchors=sorted(set(a)-set(e)),detections=rows)
    return dict(status='pass_numeric' if all(x['pass_numeric'] for x in results.values()) else 'fail_numeric',models=results)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--actual',type=Path,required=True,help='Independent captured observation JSON; see samples/readme.md')
    p.add_argument('--output',type=Path,default=ROOT/'build/out/inference_comparison.json')
    p.add_argument('--logit-tol',type=int,default=0)
    p.add_argument('--box-tol',type=float,default=.001)
    p.add_argument('--score-tol',type=float,default=.00001)
    args=p.parse_args()
    doc=json.loads(args.actual.read_text(encoding='utf8'))
    meta=doc['capture'];actual=doc['results']
    if meta.get('execution') not in ('board','rtl_simulation','cpu_reference'):raise ValueError('Capture execution type required')
    for key in ('run_id','captured_at','firmware_or_design_sha256','raw_evidence'):
        if not isinstance(meta.get(key),str) or not meta[key].strip():raise ValueError('Missing capture field: '+key)
    h=meta['firmware_or_design_sha256']
    if len(h)!=64 or any(x not in '0123456789abcdef' for x in h):raise ValueError('Design/firmware SHA256 must be lowercase hexadecimal')
    evidence=(args.actual.parent/meta['raw_evidence']).resolve()
    if not evidence.is_file():raise ValueError('Raw captured evidence file not found')
    if evidence==args.actual.resolve() or evidence==SAMPLES/'expected.json':raise ValueError('Raw evidence must be an independent captured file')
    expected_hashes={k:sha(SAMPLES/name) for k,name in NAMES.items()}
    if meta.get('input_sha256')!=expected_hashes:raise ValueError('Input hashes differ from the packaged samples; compare against their own reference instead')
    expected=json.loads((SAMPLES/'expected.json').read_text())
    report=compare(expected,actual,args.logit_tol,args.box_tol,args.score_tol)
    report.update(capture=meta,actual_sha256=sha(args.actual),reference_sha256=sha(SAMPLES/'expected.json'),
        raw_evidence_sha256=sha(evidence),tolerances=dict(logits=args.logit_tol,box_pixels=args.box_tol,score=args.score_tol),
        scope='Numeric comparison of supplied captures. Execution provenance is declared by the operator; this tool does not access hardware or prove capture authenticity.')
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(report['status'],args.output)
    return 0 if report['status']=='pass_numeric' else 1

if __name__=='__main__':
    try:raise SystemExit(main())
    except (ValueError,KeyError,TypeError,OSError) as e:raise SystemExit('INVALID_OBSERVATION: '+str(e))
