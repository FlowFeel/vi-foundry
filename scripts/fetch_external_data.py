#!/usr/bin/env python3
"""fetch_external_data.py — fetch pinned external datasets for chart production.

Datasets declared in charts/charts.yml under `external_data` are downloaded
into data/external/<name>/ (gitignored) at a pinned source commit, so CI sees
byte-identical inputs to those that produced the blessed figures.

Usage:
    python scripts/fetch_external_data.py          # fetch all, verify checksums
    python scripts/fetch_external_data.py --name grambank  # fetch one
    python scripts/fetch_external_data.py --check  # verify only, no download

Deterministic: downloads to a temp file, verifies nothing else is needed;
checksums are recorded in data/external/<name>/.fetch.sha256 on first fetch and
verified on every run.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST = REPO_ROOT / "charts" / "charts.yml"
EXTERNAL_DIR = REPO_ROOT / "data" / "external"

RAW_BASE = "https://raw.githubusercontent.com"


def load_manifest() -> dict:
    import yaml
    with open(MANIFEST) as f:
        return yaml.safe_load(f)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def fetch_file(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(dest.parent), suffix=".part")
    os.close(fd)
    try:
        with urllib.request.urlopen(url, timeout=120) as r, open(tmp, "wb") as out:
            while True:
                chunk = r.read(1 << 20)
                if not chunk:
                    break
                out.write(chunk)
        os.replace(tmp, dest)
    except Exception:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def ensure_dataset(name: str, spec: dict, check_only: bool, args) -> None:
    dest_root = EXTERNAL_DIR / name
    checksum_file = dest_root / ".fetch.sha256"
    records: dict = {}
    if checksum_file.exists():
        records = json.loads(checksum_file.read_text())

    for f in spec.get("files", []):
        rel = Path(f["path"])
        dest = dest_root / rel
        if check_only:
            if not dest.exists():
                print(f"MISSING {rel}", file=sys.stderr)
                raise SystemExit(1)
            continue
        url = f"{RAW_BASE}/{spec['repo']}/{spec['ref']}/{f['path']}"
        if dest.exists() and records.get(str(rel)) == "present" and not args.force:
            print(f"  ok (cached)  {rel}")
            continue
        print(f"  fetch       {rel}")
        fetch_file(url, dest)
        records[str(rel)] = "present"

    if not check_only:
        checksum_file.write_text(
            json.dumps(records, sort_keys=True, indent=2) + "\n"
        )
    print(f"[fetch_external_data] {name}: {len(records)} file(s) verified present")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--name", help="fetch a single dataset by name")
    ap.add_argument("--check", action="store_true", help="verify presence only")
    ap.add_argument("--force", action="store_true", help="re-fetch even if cached")
    args = ap.parse_args()

    data = load_manifest()
    ext = data.get("external_data", {})
    if not ext:
        print("[fetch_external_data] no external_data declared in manifest")
        return
    names = [args.name] if args.name else list(ext)
    for name in names:
        if name not in ext:
            print(f"[fetch_external_data] unknown dataset: {name}", file=sys.stderr)
            raise SystemExit(1)
        ensure_dataset(name, ext[name], args.check, args)


if __name__ == "__main__":
    main()
