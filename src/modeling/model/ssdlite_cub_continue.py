"""Continue face_v2 on audited CUB boxes with old positives/background replay."""
import argparse
import hashlib
import json
import math
import random
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import numpy as np
import torch
from PIL import Image
from torch.utils.data import DataLoader
from bird_detection_data import BirdDataset, collate, load_manifest, manifest_hash
from ssdlite_mobilenet_v2 import load_detector, attach_background_loss
from train_bird_detector import evaluate, background_metrics, package, atomic_save

ROOT = Path (__file__).resolve().parents[1]
BASE = ROOT.parents[1] / 'build/out/modeling/background'

def sha (p):
    return hashlib.sha256 (Path (p).read_bytes()).hexdigest()

def write_json (p, value):
    Path (p).write_text (json.dumps (value, indent=2, ensure_ascii=False), encoding='utf-8')

def prepare (args):
    root = Path (args.cub)
    def table (name):
        rows = [line.split (maxsplit=1) for line in (root / name).read_text().splitlines()]
        assert len ({r[0] for r in rows}) == len (rows), name
        return dict (rows)
    images, boxes = table ('images.txt'), table ('bounding_boxes.txt')
    splits, labels = table ('train_test_split.txt'), table ('image_class_labels.txt')
    assert images.keys() == boxes.keys() == splits.keys() == labels.keys()
    cub = []
    for key, name in images.items():
        x, y, w, h = map (float, boxes[key].split())
        assert all (math.isfinite (v) for v in (x,y,w,h)) and w>0 and h>0
        assert splits[key] in ('0','1')
        cub.append (dict (id='cub:'+key, path=str ((root/'images'/name).resolve()),
                         boxes=[[x,y,x+w,y+h]], species=labels[key], source='cub',
                         official_split='train' if splits[key]=='1' else 'test'))
    groups = defaultdict (list)
    for r in cub:
        if r['official_split']=='test': r['split']='test'
        else: groups[r['species']].append (r)
    for species, rows in sorted (groups.items()):
        random.Random (f'{args.seed}:cub:{species}').shuffle (rows)
        for i,r in enumerate (rows): r['split']='val' if i<max (1,round (len (rows)*.1)) else 'train'
    old = load_manifest (args.old_manifest)['records']
    old = [dict (r, source='old') for r in old]
    negatives = [dict (r, source='background') for r in json.loads (Path(args.background_manifest).read_text())]
    def audit (r):
        r=dict (r)
        with Image.open (r['path']) as im:
            im=im.convert ('RGB');im.load();w,h=im.size
            r['pixel_sha256']=hashlib.sha256 (str (im.size).encode()+im.tobytes()).hexdigest()
        if 'width' in r: assert (r['width'],r['height'])==(w,h),r['path']
        r.update (width=w,height=h)
        fixed=[]
        for x1,y1,x2,y2 in r['boxes']:
            b=[max (0.,x1),max (0.,y1),min (float(w),x2),min (float(h),y2)]
            # Official CUB boxes occasionally extend a few pixels past the image.
            overrun=max(abs(a-c) for a,c in zip(b,[x1,y1,x2,y2]))
            assert b[2]>b[0] and b[3]>b[1] and overrun<=max(w,h)*.05,r['path']
            r['box_clip_pixels']=max(r.get('box_clip_pixels',0),overrun)
            fixed.append(b)
        r['boxes']=fixed
        return r
    def checked (r):
        try: return audit(r),None
        except (AssertionError,ValueError,OSError) as exc:
            return None,dict(path=r['path'],source=r['source'],reason=str(exc) or 'Invalid annotation or dimensions')
    with ThreadPoolExecutor (max_workers=8) as pool:
        checked_rows=list (pool.map (checked,cub+old+negatives))
    errors=[e for r,e in checked_rows if e]
    write_json(Path(args.output)/'excluded_images.json',errors)
    if len(errors)>len(cub+old+negatives)*.02:raise ValueError('More than 2% audit failures; inspect excluded_images.json')
    records=[r for r,e in checked_rows if r]
    # Holdout wins over training; remove exact decoded-pixel duplicates.
    records.sort (key=lambda r:({'test':0,'val':1,'train':2}[r['split']],r['source'],r['id']))
    seen={};kept=[];duplicates=[]
    for r in records:
        digest=r['pixel_sha256']
        if digest in seen:
            first=seen[digest]
            assert bool(first['boxes'])==bool(r['boxes']), 'Conflicting bird/background annotation'
            duplicates.append(dict(removed=r['path'],split=r['split'],kept=first['path'],kept_split=first['split']))
        else: seen[digest]=r;kept.append(r)
    counts=Counter(r['source']+':'+r['split'] for r in kept)
    assert all(counts[f'{s}:{p}'] for s in ('cub','old','background') for p in ('train','val'))
    summary=dict(counts=dict(counts),cub_source_images=len(cub),duplicates=duplicates,excluded_images=errors,
                 clipped_boxes=[dict(path=r['path'],pixels=r['box_clip_pixels']) for r in kept if r.get('box_clip_pixels',0)>0],
                 seed=args.seed,manifest_sha256=manifest_hash(kept),
                 split_policy='CUB official test held out; stratified 10% official train for val; exact pixel dedup across all sources',
                 test_used_for_model_selection=False,
                 caveat='Existing checkpoint historical pretraining exposure is not certified by this dedup audit')
    write_json(Path(args.output)/'manifest.json',dict(schema=1,summary=summary,records=kept))
    write_json(Path(args.output)/'audit.json',summary)
    print(json.dumps(summary,ensure_ascii=True),flush=True)
    return kept

def train (args, rows):
    out=Path(args.output);device='cuda'
    if not torch.cuda.is_available(): raise RuntimeError('CUDA required; refusing accidental long CPU training')
    random.seed(args.seed);np.random.seed(args.seed);torch.manual_seed(args.seed);torch.set_num_threads(4)
    fingerprint=manifest_hash(rows);initial_hash=sha(args.weights)
    model=load_detector(args.weights,device)
    positive=[r for r in rows if r['split']=='train' and r['boxes']]
    negative=BirdDataset([r for r in rows if r['split']=='train' and not r['boxes']],True)
    loaders={s:DataLoader(BirdDataset([r for r in rows if r['source']==s and r['split']=='val']),batch_size=args.batch_size,collate_fn=collate) for s in ('cub','old')}
    bg=[r for r in rows if r['source']=='background' and r['split']=='val']
    def measure():
        return {**{s:evaluate(model,l,device,.3) for s,l in loaders.items()},'background':background_metrics(model,bg,device,.3)}
    write_json(out/'run_config.json',dict(args=vars(args),initial_sha256=initial_hash,device=torch.cuda.get_device_name(0),manifest_sha256=fingerprint,BN_frozen=True,negative_fraction=.25))
    print('BASELINE_EVALUATION_START',flush=True)
    baseline=json.loads((out/'baseline.json').read_text()) if args.resume else measure()
    write_json(out/'baseline.json',baseline);print('BASELINE '+json.dumps(baseline),flush=True)
    attach_background_loss(model,64,1.)
    optimizer=torch.optim.AdamW([{'params':model.backbone.parameters(),'lr':args.lr*.1},{'params':model.head.parameters(),'lr':args.lr}],weight_decay=1e-4)
    scheduler=torch.optim.lr_scheduler.CosineAnnealingLR(optimizer,T_max=args.epochs)
    nneg=max(1,round(args.batch_size*.25))
    loader=DataLoader(BirdDataset(positive,True),batch_size=args.batch_size-nneg,shuffle=True,collate_fn=collate)
    best=(baseline['cub']['ap50']+baseline['old']['ap50'])/2;candidate_best=-1.;accepted=False
    start=0
    if args.resume:
        saved=torch.load(out/'last_checkpoint.pt',map_location='cpu',weights_only=False)
        assert saved['manifest_sha256']==fingerprint
        for field in ('epochs','batch_size','lr','seed','weights'):
            assert saved['cub_finetune'][field]==getattr(args,field),field
        model.load_state_dict(saved['model']);optimizer.load_state_dict(saved['optimizer']);scheduler.load_state_dict(saved['scheduler'])
        random.setstate(saved['rng_python']);np.random.set_state(saved['rng_numpy']);torch.set_rng_state(saved['rng_torch']);torch.cuda.set_rng_state_all(saved['rng_cuda'])
        start=saved['epoch']+1;best=saved['best'];candidate_best=saved['candidate_best'];accepted=saved['accepted']
    for epoch in range(start,args.epochs):
        began=time.monotonic();model.train()
        for module in model.modules():
            if isinstance(module,torch.nn.BatchNorm2d):module.eval()
        total=0.
        for step,(images,targets) in enumerate(loader):
            samples=list(zip(images,targets))+[negative[random.randrange(len(negative))] for _ in range(nneg)]
            images,targets=collate(samples);optimizer.zero_grad(set_to_none=True)
            losses=model([x.to(device) for x in images],[{k:v.to(device) for k,v in t.items()} for t in targets]);loss=sum(losses.values())
            if not torch.isfinite(loss):raise FloatingPointError(str(losses))
            loss.backward();torch.nn.utils.clip_grad_norm_(model.parameters(),10);optimizer.step();total+=loss.item()
            if step%50==0:print(f'epoch={epoch+1}/{args.epochs} step={step}/{len(loader)} loss={loss.item():.5f}',flush=True)
        metrics=measure();scheduler.step();score=(metrics['cub']['ap50']+metrics['old']['ap50'])/2
        gates=dict(old_recall=metrics['old']['recall_at_score']>=baseline['old']['recall_at_score']-.02,
                   old_ap=metrics['old']['ap50']>=baseline['old']['ap50']-.02,
                   cub_ap=metrics['cub']['ap50']>=baseline['cub']['ap50'],
                   background=metrics['background']['false_positive_image_rate']<=baseline['background']['false_positive_image_rate']+.02)
        payload=package(model,epoch,metrics,fingerprint)
        payload['cub_finetune']=vars(args);atomic_save(payload,out/'last_weights.pt')
        if score>candidate_best:candidate_best=score;atomic_save(payload,out/'best_candidate_weights.pt')
        if all(gates.values()) and score>best:best=score;accepted=True;atomic_save(payload,out/'best_weights.pt')
        atomic_save(dict(**payload,optimizer=optimizer.state_dict(),scheduler=scheduler.state_dict(),rng_python=random.getstate(),rng_numpy=np.random.get_state(),rng_torch=torch.get_rng_state(),rng_cuda=torch.cuda.get_rng_state_all(),best=best,candidate_best=candidate_best,accepted=accepted),out/'last_checkpoint.pt')
        report=dict(epoch=epoch+1,loss=total/len(loader),metrics=metrics,gates=gates,accepted_checkpoint_exists=accepted,seconds=time.monotonic()-began)
        with (out/'history.jsonl').open('a') as f:f.write(json.dumps(report)+'\n')
        print(json.dumps(report),flush=True)
    assert sha(args.weights)==initial_hash
    chosen=out/('best_weights.pt' if accepted else 'best_candidate_weights.pt')
    model=load_detector(chosen,device)
    test_metrics={s:evaluate(model,DataLoader(BirdDataset([r for r in rows if r['source']==s and r['split']=='test']),batch_size=args.batch_size,collate_fn=collate),device,.3) for s in ('cub','old')}
    write_json(out/'evaluation_test.json',dict(weights=str(chosen),accepted_for_deployment=accepted,metrics=test_metrics))
    write_json(out/'completion.json',dict(completed=True,accepted=accepted,best_score=best,original_weights_unchanged=True,test_evaluation_pending=False))
    print('TRAINING_COMPLETE accepted='+str(accepted),flush=True)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=['audit','train'])
    p.add_argument('--cub',required=True)
    p.add_argument('--old-manifest',required=True)
    p.add_argument('--background-manifest',required=True)
    p.add_argument('--weights',required=True)
    p.add_argument('--output',default=str(ROOT.parents[1]/'build/out/modeling/cub_continue'))
    p.add_argument('--epochs',type=int,default=10);p.add_argument('--batch-size',type=int,default=8)
    p.add_argument('--lr',type=float,default=1e-4);p.add_argument('--seed',type=int,default=2276)
    p.add_argument('--resume',action='store_true')
    args=p.parse_args();assert args.epochs>0 and args.batch_size>=2 and args.lr>0
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    if args.command=='train' and (out/'run_config.json').exists() and not args.resume:raise ValueError('Run exists; use --resume or choose a new output')
    rows=prepare(args) if not (out/'manifest.json').exists() else load_manifest(out/'manifest.json')['records']
    if args.command=='train':train(args,rows)

if __name__=='__main__':main()
