"""Export only verified manifest files, excluding Git and generated outputs."""
from pathlib import Path
import argparse, hashlib, json, zipfile
from verify_package import verify, ROOT

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT/'build/out/github_pack.zip')
    args=parser.parse_args()
    manifest=verify()
    paths=sorted([*manifest['files'], 'report/package_manifest.json'])
    destination=args.output.resolve()
    if destination.exists():raise SystemExit('Output exists; choose another --output name to retain the previous archive.')
    if destination in [(ROOT/p).resolve() for p in paths]:raise SystemExit('Output cannot replace a package input.')
    destination.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(destination,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for rel in paths:
            data=(ROOT/rel).read_bytes()
            if rel in manifest['files'] and hashlib.sha256(data).hexdigest()!=manifest['files'][rel]:
                raise RuntimeError('Source changed during export: '+rel)
            archive.writestr('github_pack/'+rel,data)
    with zipfile.ZipFile(destination) as archive:
        assert archive.testzip() is None
        for rel,digest in manifest['files'].items():
            assert hashlib.sha256(archive.read('github_pack/'+rel)).hexdigest()==digest,rel
    print(json.dumps(dict(status='pass',archive=str(destination),files=len(paths),
        sha256=hashlib.sha256(destination.read_bytes()).hexdigest(),generated_files_included=False),indent=2))

if __name__=='__main__':main()
