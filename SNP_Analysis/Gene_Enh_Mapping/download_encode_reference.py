#!/usr/bin/env python3
"""Download the six fixed public ENCODE reference files and verify MD5 checksums."""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request


MANIFEST = Path(__file__).with_name('encode_reference_manifest.json')


def md5(path):
    digest = hashlib.md5()
    with Path(path).open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def verify_reference(directory):
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    for item in manifest:
        path = directory / (item['accession'] + '.bed.gz')
        if not path.is_file() or md5(path) != item['md5sum']:
            raise ValueError(f'Missing or checksum-mismatched reference: {path}')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--outdir', type=Path, required=True)
    args = parser.parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)
    for item in json.loads(MANIFEST.read_text(encoding='utf-8')):
        dest = args.outdir / (item['accession'] + '.bed.gz')
        if dest.exists():
            if md5(dest) != item['md5sum']:
                raise ValueError(f'Existing file has wrong checksum: {dest}; move it aside before retrying')
            print(f'Already verified: {dest.name}')
            continue
        temporary = dest.with_suffix('.part')
        request = urllib.request.Request(item['url'], headers={'User-Agent': 'ENCODE-concordance/1.0'})
        with urllib.request.urlopen(request, timeout=120) as response, temporary.open('wb') as output:
            while block := response.read(1024 * 1024):
                output.write(block)
        if md5(temporary) != item['md5sum']:
            raise ValueError(f'Download checksum failed: {temporary}')
        temporary.replace(dest)
        print(f'Downloaded and verified: {dest.name}')
    verify_reference(args.outdir)


if __name__ == '__main__':
    main()
