#!/usr/bin/env python3
"""render_charts.py — regenerate and verify the chart manifest.

The single entry point for the charts cycle. Reads charts/charts.yml, runs
every producer, and compares regenerated outputs against the committed
(blessed) files.

Modes:
    python scripts/render_charts.py            # verify: regenerate, compare, restore
    python scripts/render_charts.py --refresh  # regenerate + write new hashes to manifest
    python scripts/render_charts.py --list     # print manifest summary

Verify mode is NON-MUTATING: it backs up the committed outputs, regenerates,
compares hashes, then restores the originals. The working tree stays clean.
It exits nonzero on any mismatch or missing output — a drifted figure fails
the gate.

--refresh is the ONLY way to bless an intentional figure change: it
regenerates in place, updates expected_sha256 in charts.yml, and the new PNGs
must be committed together with the manifest.

Determinism note: producers run with fixed PYTHONHASHSEED so dict/set
iteration order is stable across runs.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST = REPO_ROOT / "charts" / "charts.yml"

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install -r charts/requirements.txt", file=sys.stderr)
    sys.exit(1)


OUTPUT_BASE = REPO_ROOT / "data" / "formula-analysis"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def load_manifest() -> dict:
    with open(MANIFEST) as f:
        return yaml.safe_load(f)


def save_manifest(data: dict) -> None:
    with open(MANIFEST, "w") as f:
        yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)


def run_producer(script: str) -> None:
    script_path = REPO_ROOT / script
    env = dict(os.environ)
    env["PYTHONHASHSEED"] = "0"
    subprocess.run(
        [sys.executable, str(script_path)],
        cwd=str(REPO_ROOT),
        env=env,
        check=True,
    )


def run_all(data: dict) -> None:
    seen: set[str] = set()
    for c in data["charts"]:
        if c["producer"] not in seen:
            seen.add(c["producer"])
            print(f"== run {c['producer']}")
            run_producer(c["producer"])


def all_outputs(data: dict) -> list[Path]:
    return [REPO_ROOT / out for c in data["charts"] for out in c["outputs"]]


def verify_against_manifest(data: dict) -> int:
    failures = 0
    for c in data["charts"]:
        for out in c["outputs"]:
            p = REPO_ROOT / out
            if not p.exists():
                print(f"FAIL missing output: {out}")
                failures += 1
                continue
            actual = sha256_file(p)
            expected = c.get("expected_sha256")
            if expected is None or expected == "PLACEHOLDER":
                print(f"FAIL no blessed hash for {out} (run --refresh first)")
                failures += 1
            elif actual != expected:
                print(f"FAIL hash mismatch {out}\n  actual   {actual}\n  expected {expected}")
                failures += 1
            else:
                print(f"ok   {out}  {actual[:12]}")
    return failures


def backup_output_dir() -> tuple[Path | None, Path | None]:
    """Move the whole output dir aside (producers also emit JSON sidecars)."""
    if not OUTPUT_BASE.exists():
        return None, None
    bak = OUTPUT_BASE.with_name(OUTPUT_BASE.name + ".bak")
    if bak.exists():
        shutil.rmtree(bak)
    shutil.move(str(OUTPUT_BASE), str(bak))
    return OUTPUT_BASE, bak


def restore_output_dir(pair: tuple[Path | None, Path | None]) -> None:
    orig, bak = pair
    if bak is None or not bak.exists():
        return
    if orig.exists():
        shutil.rmtree(orig)
    shutil.move(str(bak), str(orig))


def list_charts(data: dict) -> None:
    for c in data["charts"]:
        outs = ", ".join(Path(o).name for o in c["outputs"])
        print(f"{c['id']:<40} {c['producer']:<42} -> {outs}")


def verify_mode(data: dict) -> None:
    bak = backup_output_dir()
    try:
        run_all(data)
        failures = verify_against_manifest(data)
    finally:
        restore_output_dir(bak)
    if failures:
        print(f"\n[render_charts] {failures} failure(s) — a figure drifted or is un-blessed. "
              f"Intentional changes require `--refresh` + commit.")
        sys.exit(1)
    print("\n[render_charts] all charts verified against blessed hashes (working tree restored)")


def refresh_mode(data: dict) -> None:
    run_all(data)
    for c in data["charts"]:
        for out in c["outputs"]:
            p = REPO_ROOT / out
            if not p.exists():
                print(f"FAIL missing output: {out}")
                continue
            c["expected_sha256"] = sha256_file(p)
            print(f"blessed {out}  {c['expected_sha256'][:12]}")
    save_manifest(data)
    print("[render_charts] manifest refreshed — commit charts.yml + regenerated PNGs together")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--refresh", action="store_true", help="regenerate + bless new hashes")
    ap.add_argument("--list", action="store_true", help="print manifest summary")
    args = ap.parse_args()

    data = load_manifest()

    if args.list:
        list_charts(data)
        return
    if args.refresh:
        refresh_mode(data)
        return
    print("== charts gate (verify blessed outputs)")
    verify_mode(data)


if __name__ == "__main__":
    main()
