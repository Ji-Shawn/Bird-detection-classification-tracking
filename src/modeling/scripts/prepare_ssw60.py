"""Prepare SSW60 data only; preserve the source recording split and augmentation. Never train."""
import os
import shutil
import argparse
import json
import re
from pathlib import Path
from datetime import datetime

import numpy as np
import pandas as pd
import librosa as lba
from numpy.random import default_rng

WORKING_DIRECTORY = None
DIR_SSW = None

SR = 32000
iSR5 = SR*5
SEED = 2276

DIR_MELS = './mels/'
DIR_CFG  = './config/'
DIR_IMGS = './images/'
REGISTRY_MELS = DIR_CFG + 'registry_mels.html'
LOG = './logs/prepare_ssw60.txt'

WIN_OFFSETS_TRN = [0.0, 1.25, 2.5, 3.75, 5.0]   # 10s clip -> 5 windows (augmented)
WIN_OFFSETS_VAL = [0.0, 5.0]                    # non-overlapping, clean

from audio_preprocessing import get_noise

def load_source_table(name):
    taxa = pd.read_csv(DIR_SSW + 'taxa.csv')
    if not {'label', 'species_code'}.issubset(taxa.columns) or taxa.empty:
        raise ValueError('taxa.csv needs nonempty label/species_code columns')
    if taxa[['label', 'species_code']].isna().any().any() or not taxa.label.is_unique or not taxa.species_code.is_unique:
        raise ValueError('taxa labels and species codes must be nonempty and unique')
    if not all(re.fullmatch(r'[a-z0-9_-]+', str(value)) for value in taxa.species_code):
        raise ValueError('species_code must use lowercase ASCII letters, digits, underscore or hyphen')
    frame = pd.read_csv(DIR_SSW + name)
    if not {'asset_id', 'label'}.issubset(frame.columns) or frame.empty:
        raise ValueError(name + ' needs nonempty asset_id/label columns')
    if frame[['asset_id', 'label']].isna().any().any() or not frame.asset_id.is_unique:
        raise ValueError(name + ': asset_id must be nonempty and unique; do not split duplicate recordings')
    if not all(re.fullmatch(r'[a-z0-9_-]+', str(value)) for value in frame.asset_id):
        raise ValueError(name + ': asset_id must be a lowercase ASCII filename stem without path separators')
    frame['bird'] = frame.label.map(dict(zip(taxa.label, taxa.species_code)))
    if frame.bird.isna().any():
        raise ValueError(name + ': label missing from taxa.csv')
    return frame

def render_mel (nax):
    spec = lba.feature.melspectrogram (y = nax, sr = SR, n_mels = 128, n_fft = 1024,
                                       hop_length = 400, fmin = 20, fmax = 16000)
    return lba.power_to_db (spec, ref = np.max)


def stage_audio (rng):
    da = load_source_table('audio_ml.csv')

    # own recording-level split (SSW60's official test is temporally shifted:
    # larger asset_ids = newer recordings, and the fine-tune runs showed a big
    # train/val domain gap). All windows of a recording stay in the same split.
    da['split'] = 'TRN'
    for bird, dfg in da.groupby ('bird'):
        idx = dfg.index.to_numpy()
        perm = rng.permutation (len (idx))
        nval = max (1, int (0.1*len (idx)))
        da.loc[idx[perm[:nval]], 'split'] = 'VAL'

    rows = []
    for i, row in enumerate (da.itertuples()):
        if i % 200 == 0:
            print (f'[stage_audio] files : {i}/{len (da)}', flush = True)
        sbdir = DIR_MELS + row.bird
        os.makedirs (sbdir, exist_ok = True)
        offsets = WIN_OFFSETS_TRN if row.split == 'TRN' else WIN_OFFSETS_VAL

        try:
            nax, _ = lba.load (DIR_SSW + f'audio_ml/{row.asset_id}.wav', sr = SR,
                               res_type = 'kaiser_fast', mono = True)
        except Exception as error:
            with open (LOG, 'a') as flog:
                print ('Error : ', f'audio_ml/{row.asset_id}.wav', error, file = flog)
            raise RuntimeError('Audio preparation failed: ' + str(row.asset_id)) from error

        for w in range (len (offsets)):
            off = offsets[w]
            seg = nax[int (off*SR) : int (off*SR) + iSR5]
            if seg.shape[0] < iSR5:                 # center zero-pad to 5s
                pad = iSR5 - seg.shape[0]
                seg = np.pad (seg, (pad//2, pad - pad//2))
            if row.split == 'TRN' and w >= 3:       # windows 3,4 get colored noise; 0,1,2 stay clean
                seg = seg + get_noise (seg, rng.uniform (0.1, 0.3), rng.uniform (200, 750),
                                       4000, 9000, 0.14*rng.uniform (3, 6),
                                       rng.uniform (0.1, 0.3), rng, SR)
            fmel = f'{sbdir}/{row.asset_id}_w{w}.npy'
            np.save (fmel, render_mel (seg))
            rows.append ((fmel, row.bird, row.split))

    drm = pd.DataFrame (rows, columns = ['sname', 'bird', 'split'])
    drm.to_html (REGISTRY_MELS, encoding = 'UTF-8')
    print (f'[stage_audio] done : {len (drm)} samples, '
           f'{drm["bird"].nunique()} classes -> {REGISTRY_MELS}', flush = True)


def stage_images ():
    for csv, prefix in [('images_nabirds.csv', 'nab'), ('images_inat.csv', 'inat')]:
        di = load_source_table(csv)
        for i, row in enumerate (di.itertuples()):
            if i % 2000 == 0:
                print (f'[stage_images {prefix}] : {i}/{len (di)}', flush = True)
            sbdir = DIR_IMGS + row.bird
            os.makedirs (sbdir, exist_ok = True)
            dst = f'{sbdir}/{prefix}_{row.asset_id}.jpg'
            if os.path.isfile (dst):
                continue
            try:
                shutil.copy (DIR_SSW + f'{csv[:-4]}/{row.asset_id}.jpg', dst)
            except OSError as error:
                with open (LOG, 'a') as flog:
                    print ('Error : ', csv, row.asset_id, error, file = flog)
                raise RuntimeError('Image preparation failed: ' + str(row.asset_id)) from error
        print (f'[stage_images {prefix}] done : {len (di)}', flush = True)


def main ():
    global WORKING_DIRECTORY, DIR_SSW
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ssw', type=Path, required=True, help='Read-only SSW60 source root')
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[3] / 'build/out/modeling/prepared')
    parser.add_argument('--component', choices=['audio', 'image', 'both'], default='both')
    args = parser.parse_args()
    if not args.ssw.is_dir():
        parser.error('--ssw must be an existing source dataset directory')
    output = args.output.resolve()
    if output == args.ssw.resolve() or args.ssw.resolve() in output.parents:
        parser.error('Output must be outside the read-only source dataset')
    if output.exists() and any(output.iterdir()):
        parser.error('Output is nonempty; select a new empty directory. Partial/cached preparation is not reused')
    previous = output / 'preparation.json'
    WORKING_DIRECTORY = str(output)
    DIR_SSW = args.ssw.resolve().as_posix().rstrip('/') + '/'
    output.mkdir(parents=True, exist_ok=True)
    os.chdir(output)
    for directory in (DIR_MELS, DIR_CFG, DIR_IMGS, './logs'):
        os.makedirs(directory, exist_ok=True)
    metadata = dict(recipe='ssw60_recording_seed2276_v1', seed=SEED, source=DIR_SSW,
                    component=args.component, status='incomplete',
                    audio_split='Per-species random 10% recording holdout; official split is not used',
                    image_split='Images copied; classifier uses per-class seeded 90/10 image split',
                    training_started=False)
    previous.write_text(json.dumps(metadata, indent=2), encoding='utf8')
    with open(LOG, 'w') as flog:
        print('prepare_ssw60 started:', datetime.now(), file=flog)
    if args.component in ('audio', 'both'):
        stage_audio(default_rng(SEED))
    if args.component in ('image', 'both'):
        stage_images()
    metadata['status'] = 'complete'
    previous.write_text(json.dumps(metadata, indent=2), encoding='utf8')
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
