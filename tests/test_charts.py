"""tests/test_charts.py — determinism, conformance, baseline, freshness.

The charts gate. Run with:  python -m pytest tests/test_charts.py -q

Covers the four disciplines of the charts cycle:
  * determinism  — regenerating twice yields byte-identical outputs
  * conformance  — every manifest entry produces a non-empty output file
  * baseline     — regenerated hash matches the blessed hash in charts.yml
  * freshness    — no committed output is newer than its committed inputs

These tests are non-mutating: the committed outputs are backed up and restored.
"""
import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST = REPO_ROOT / "charts" / "charts.yml"
RENDER = REPO_ROOT / "scripts" / "render_charts.py"
OUTPUT_BASE = REPO_ROOT / "data" / "formula-analysis"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


@pytest.fixture(scope="session")
def manifest():
    with open(MANIFEST) as f:
        return yaml.safe_load(f)


def outputs_of(manifest):
    return [REPO_ROOT / out for c in manifest["charts"] for out in c["outputs"]]


# ---------------------------------------------------------------------------
# conformance
# ---------------------------------------------------------------------------
def test_every_chart_has_blessed_hash(manifest):
    for c in manifest["charts"]:
        assert c.get("expected_sha256") and c["expected_sha256"] != "PLACEHOLDER", \
            f"{c['id']} is not blessed (run `make charts-refresh`)"


def test_committed_outputs_exist_and_nonempty(manifest):
    for out in outputs_of(manifest):
        assert out.exists(), f"missing committed output {out}"
        assert out.stat().st_size > 0, f"empty committed output {out}"


def test_producers_and_inputs_exist(manifest):
    for c in manifest["charts"]:
        assert (REPO_ROOT / c["producer"]).exists(), f"missing producer {c['producer']}"
        for inp in c.get("inputs", []):
            assert (REPO_ROOT / inp).exists(), f"missing input {inp} for {c['id']}"


# ---------------------------------------------------------------------------
# freshness — inputs not newer than committed outputs (source-of-truth gate)
# ---------------------------------------------------------------------------
def test_no_output_newer_than_its_inputs(manifest):
    offenders = []
    for c in manifest["charts"]:
        for out in c["outputs"]:
            op = REPO_ROOT / out
            if not op.exists():
                continue
            for inp in c.get("inputs", []):
                # external data is pinned by source ref + fetched; its local
                # mtime is not part of the freshness contract
                if inp.startswith("data/external/"):
                    continue
                ip = REPO_ROOT / inp
                if ip.exists() and ip.stat().st_mtime > op.stat().st_mtime:
                    offenders.append(f"{out} older than input {inp}")
    assert not offenders, "stale figures (inputs newer than committed outputs):\n" + "\n".join(offenders)


# ---------------------------------------------------------------------------
# baseline + determinism — run producers against a scratch OUTPUT_BASE
# ---------------------------------------------------------------------------
def _backup_output_dir() -> Path | None:
    """Move the whole output dir aside (producers also emit JSON sidecars)."""
    if not OUTPUT_BASE.exists():
        return None
    bak = OUTPUT_BASE.with_name(OUTPUT_BASE.name + ".testbak")
    if bak.exists():
        shutil.rmtree(bak)
    os.replace(OUTPUT_BASE, bak)
    return bak


def _restore_output_dir(bak: Path | None) -> None:
    if bak is None:
        return
    if OUTPUT_BASE.exists():
        shutil.rmtree(OUTPUT_BASE)
    os.replace(bak, OUTPUT_BASE)


def _run_all(manifest):
    env = dict(os.environ)
    env["PYTHONHASHSEED"] = "0"
    seen = set()
    for c in manifest["charts"]:
        if c["producer"] in seen:
            continue
        seen.add(c["producer"])
        subprocess.run(
            [sys.executable, str(REPO_ROOT / c["producer"])],
            cwd=str(REPO_ROOT), env=env, check=True,
        )


def _regenerate_to_scratch(scratch_dir: Path, manifest):
    """Regenerate all outputs into scratch without touching committed files."""
    bak = _backup_output_dir()
    try:
        _run_all(manifest)
        # move regenerated outputs to scratch (shutil.move handles cross-device)
        for out in outputs_of(manifest):
            p = REPO_ROOT / out
            if p.exists():
                dst = scratch_dir / out.relative_to(REPO_ROOT)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(p), str(dst))
    finally:
        _restore_output_dir(bak)


@pytest.fixture()
def regenerated(tmp_path, manifest):
    """Run all producers once, snapshot outputs to tmp, restore originals."""
    _regenerate_to_scratch(tmp_path, manifest)
    return tmp_path


def test_baseline_hashes_match_blessed(manifest, regenerated):
    for c in manifest["charts"]:
        for out in c["outputs"]:
            p = regenerated / out
            assert p.exists(), f"producer did not emit {out}"
            actual = sha256_file(p)
            assert actual == c["expected_sha256"], \
                f"{c['id']}: regenerated {actual} != blessed {c['expected_sha256']}"


def test_determinism_two_runs_identical(manifest, tmp_path):
    a = tmp_path / "run_a"
    b = tmp_path / "run_b"
    a.mkdir()
    b.mkdir()
    _regenerate_to_scratch(a, manifest)
    _regenerate_to_scratch(b, manifest)
    for c in manifest["charts"]:
        for out in c["outputs"]:
            pa, pb = a / out, b / out
            assert pa.exists() and pb.exists(), f"missing output {out}"
            assert sha256_file(pa) == sha256_file(pb), \
                f"{c['id']}: nondeterministic output {out}"
