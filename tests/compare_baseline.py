"""Compare simulation output to baseline oracle within numerical tolerance.

Reads baseline/oracle.yml (YAML — the human-readable source of truth).
Compares against pipeline output. Reports exact path and deviation on failure.
JSON is used only as internal serialization for the comparison step.
"""
import sys
import math
import yaml
import json
from pathlib import Path


def load_baseline(baseline_dir):
    """Load the YAML baseline oracle."""
    oracle_path = Path(baseline_dir) / "oracle.yml"
    if not oracle_path.exists():
        print(f"FAIL: baseline oracle not found at {oracle_path}", file=sys.stderr)
        sys.exit(1)
    with open(oracle_path) as f:
        return yaml.safe_load(f)


def load_results(output_dir):
    """Load pipeline results from output directory."""
    results_path = Path(output_dir) / "results.yml"
    if results_path.exists():
        with open(results_path) as f:
            return yaml.safe_load(f)
    # Fallback to JSON
    results_path = Path(output_dir) / "results.json"
    if not results_path.exists():
        print(f"FAIL: results not found at {output_dir}", file=sys.stderr)
        sys.exit(1)
    with open(results_path) as f:
        return json.load(f)


def compare_values(actual, expected, tolerance, path=""):
    """Recursively compare values within numerical tolerance."""
    failures = []

    if isinstance(expected, dict):
        for key, exp_val in expected.items():
            act_val = actual.get(key) if isinstance(actual, dict) else None
            failures.extend(compare_values(act_val, exp_val, tolerance, f"{path}.{key}"))
    elif isinstance(expected, list):
        for i, (a, e) in enumerate(zip(actual or [], expected)):
            failures.extend(compare_values(a, e, tolerance, f"{path}[{i}]"))
    elif isinstance(expected, (int, float)):
        if actual is None:
            failures.append(f"{path}: expected {expected}, got None")
        elif isinstance(actual, str) or isinstance(actual, bool):
            failures.append(f"{path}: expected numeric {expected}, got {type(actual).__name__} '{actual}'")
        elif math.isnan(actual):
            failures.append(f"{path}: expected {expected}, got NaN")
        elif abs(actual - expected) > tolerance:
            failures.append(
                f"{path}: expected {expected}, got {actual} "
                f"(diff {abs(actual - expected):.6f} > {tolerance})"
            )
    elif isinstance(expected, str):
        if actual != expected:
            failures.append(f"{path}: expected '{expected}', got '{actual}'")
    elif isinstance(expected, bool):
        if actual != expected:
            failures.append(f"{path}: expected {expected}, got {actual}")

    return failures


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Compare results to baseline oracle")
    parser.add_argument("--tolerance", type=float, default=0.001)
    parser.add_argument("--baseline", default="/workspace/baseline")
    parser.add_argument("--output", default="/workspace/output")
    args = parser.parse_args()

    baseline = load_baseline(args.baseline)
    results = load_results(args.output)

    all_failures = []
    for test_name, test_spec in baseline.items():
        if not isinstance(test_spec, dict) or "values" not in test_spec:
            continue
        expected = test_spec["values"]
        tolerance = test_spec.get("tolerance", args.tolerance)
        actual = results.get(test_name, {})
        if isinstance(actual, dict) and "values" in actual:
            actual = actual["values"]
        failures = compare_values(actual, expected, tolerance, test_name)
        all_failures.extend(failures)

    if all_failures:
        print(f"FAIL: {len(all_failures)} regression(s) found:")
        for f in all_failures:
            print(f"  ✗ {f}")
        sys.exit(1)
    else:
        print(f"✓ All results match baseline oracle within tolerance {args.tolerance}")
        sys.exit(0)


if __name__ == "__main__":
    main()
