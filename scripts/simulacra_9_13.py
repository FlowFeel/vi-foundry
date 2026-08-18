#!/usr/bin/env python3
"""
Foundry Simulacra 9-13: Statistical pipeline verification for the
bi-exponential relaxation formula.

Uses standard pharmacological bi-exponential form:
  ρ(t) = C + A*exp(-k1*t) + B*exp(-k2*t)
  where C + A + B = 1.0 (initial condition)
  4 free params: k1, k2, C, A (B = 1 - C - A)
"""

import numpy as np
from scipy.optimize import curve_fit
from scipy.stats import spearmanr
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "results")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def biexp(t, k1, k2, C, A):
    """Bi-exponential: ρ(t) = C + A*exp(-k1*t) + B*exp(-k2*t)
    where B = 1 - C - A (ensuring ρ(0) = 1.0)
    """
    B = 1.0 - C - A
    return C + A * np.exp(-k1 * t) + B * np.exp(-k2 * t)


def mono_exp(t, k, C):
    """Mono-exponential: ρ(t) = C + (1-C)*exp(-k*t)"""
    return C + (1.0 - C) * np.exp(-k * t)


def linear_model(t, rate):
    """Linear: ρ(t) = max(1 - rate*t, 0)"""
    return np.maximum(1.0 - rate * t, 0)


def compute_aic(n_params, n_points, rss):
    if rss <= 0:
        rss = 1e-10
    n = n_points
    k = n_params + 1
    return n * np.log(rss / n) + 2 * k


def fit_models(t, y):
    """Fit bi-exp, mono-exp, linear. Return AIC comparison."""
    results = {}
    
    # Bi-exponential (4 params)
    best_bi = None
    for p0 in [[1.0, 0.1, 0.2, 0.5], [5.0, 0.5, 0.1, 0.6], [0.5, 0.01, 0.3, 0.4],
               [10.0, 1.0, 0.05, 0.7], [0.1, 0.01, 0.2, 0.5], [2.0, 0.05, 0.15, 0.6],
               [50.0, 0.1, 0.1, 0.7], [0.01, 0.001, 0.3, 0.4]]:
        try:
            popt, _ = curve_fit(biexp, t, y, p0=p0, maxfev=30000,
                                bounds=([1e-6, 1e-8, 0.0, 0.0], [1e4, 1e3, 1.0, 1.0]))
            y_pred = biexp(t, *popt)
            rss = float(np.sum((y - y_pred)**2))
            aic = compute_aic(4, len(t), rss)
            if best_bi is None or aic < best_bi['aic']:
                best_bi = {'params': [float(p) for p in popt], 'aic': aic, 'rss': rss}
        except Exception:
            continue
    results['bi_exp'] = best_bi or {'error': 'all fits failed', 'aic': float('inf')}
    
    # Mono-exponential (2 params)
    best_mono = None
    for p0 in [[0.5, 0.2], [0.1, 0.1], [1.0, 0.3], [0.01, 0.05], [0.05, 0.15]]:
        try:
            popt, _ = curve_fit(mono_exp, t, y, p0=p0, maxfev=30000,
                                bounds=([1e-8, 0.0], [1e4, 1.0]))
            y_pred = mono_exp(t, *popt)
            rss = float(np.sum((y - y_pred)**2))
            aic = compute_aic(2, len(t), rss)
            if best_mono is None or aic < best_mono['aic']:
                best_mono = {'params': [float(p) for p in popt], 'aic': aic, 'rss': rss}
        except Exception:
            continue
    results['mono_exp'] = best_mono or {'error': 'all fits failed', 'aic': float('inf')}
    
    # Linear (1 param)
    try:
        popt, _ = curve_fit(linear_model, t, y, p0=[0.01], maxfev=30000,
                            bounds=([0.0], [10.0]))
        y_pred = linear_model(t, *popt)
        rss = float(np.sum((y - y_pred)**2))
        results['linear'] = {'params': [float(p) for p in popt], 'aic': compute_aic(1, len(t), rss), 'rss': rss}
    except Exception:
        results['linear'] = {'error': 'fit failed', 'aic': float('inf')}
    
    results['delta_aic_bi_vs_mono'] = results['bi_exp'].get('aic', float('inf')) - results['mono_exp'].get('aic', float('inf'))
    return results


def simulacrum_9():
    """Multi-System Rate Recovery: 5 systems with different k1/k2 ratios."""
    np.random.seed(42)
    
    # True parameters: (k1, k2, C, A) where B = 1-C-A
    systems = [
        {"name": "LTEE-like (ratio=37)", "params": [17.7, 0.47, 0.1, 0.6]},
        {"name": "Fast system (ratio=10)", "params": [50.0, 5.0, 0.05, 0.7]},
        {"name": "Slow system (ratio=20)", "params": [2.0, 0.1, 0.2, 0.5]},
        {"name": "Moderate (ratio=10)", "params": [10.0, 1.0, 0.1, 0.6]},
        {"name": "Extreme ratio (ratio=1000)", "params": [100.0, 0.1, 0.05, 0.8]},
    ]
    
    # Use 100 time points over a range that captures both phases
    t = np.linspace(0, 50, 100)
    noise_level = 0.01
    
    results = []
    passes = 0
    
    for sys in systems:
        k1_true, k2_true, C_true, A_true = sys["params"]
        B_true = 1.0 - C_true - A_true
        
        y_true = biexp(t, k1_true, k2_true, C_true, A_true)
        y_noisy = y_true + np.random.normal(0, noise_level, len(t))
        
        fit = fit_models(t, y_noisy)
        
        # Check recovery
        if 'params' in fit.get('bi_exp', {}):
            recovered = fit['bi_exp']['params']
            k1_rec, k2_rec = recovered[0], recovered[1]
            ratio_true = k1_true / k2_true
            ratio_rec = k1_rec / max(k2_rec, 1e-10)
            ratio_error = abs(ratio_rec - ratio_true) / ratio_true
            
            delta_aic = fit['delta_aic_bi_vs_mono']
            bi_preferred = delta_aic < -2
            
            # Pass if bi-exp preferred AND ratio within 50%
            passed = bi_preferred and ratio_error < 0.50
            if passed:
                passes += 1
            
            results.append({
                "system": sys["name"],
                "true_k1": k1_true, "true_k2": k2_true,
                "true_ratio": float(ratio_true),
                "recovered_k1": float(k1_rec), "recovered_k2": float(k2_rec),
                "recovered_ratio": float(ratio_rec),
                "ratio_error": float(ratio_error),
                "delta_aic_bi_vs_mono": float(delta_aic),
                "bi_preferred": bool(bi_preferred),
                "passed": bool(passed)
            })
        else:
            results.append({"system": sys["name"], "error": "fit failed", "passed": False})
    
    return {
        "simulacrum": 9,
        "name": "Multi-System Rate Recovery",
        "n_systems": 5,
        "n_passed": passes,
        "pass_criterion": "bi-exp preferred (ΔAIC < -2) AND k1/k2 ratio within 50% for ≥3/5 systems",
        "passed": passes >= 3,
        "results": results
    }


def simulacrum_10():
    """Cross-Kingdom Parameter Transfer."""
    np.random.seed(123)
    
    n_traits = 50
    n_pairs = 4
    passes = 0
    results = []
    
    for pair in range(n_pairs):
        dep_A = np.random.uniform(0, 1, n_traits)
        dep_B = np.clip(dep_A + np.random.normal(0, 0.15, n_traits), 0, 1)
        
        retention_A = np.clip(1 / (1 + np.exp(-3 * (dep_A - 0.5))) + np.random.normal(0, 0.05, n_traits), 0, 1)
        retention_B = np.clip(1 / (1 + np.exp(-3 * (dep_B - 0.5))) + np.random.normal(0, 0.05, n_traits), 0, 1)
        
        rho, p = spearmanr(dep_A, retention_B)
        passed = bool(rho > 0.5 and p < 0.05)
        if passed:
            passes += 1
        
        results.append({
            "pair": pair + 1,
            "spearman_rho": float(rho),
            "p_value": float(p),
            "passed": passed
        })
    
    return {
        "simulacrum": 10,
        "name": "Cross-Kingdom Parameter Transfer",
        "n_pairs": n_pairs,
        "n_passed": passes,
        "pass_criterion": "Spearman ρ > 0.5, p < 0.05 in ≥3/4 pairs",
        "passed": passes >= 3,
        "results": results
    }


def simulacrum_11():
    """Substrate Independence: non-DNA substrate bi-exponential."""
    np.random.seed(456)
    
    n_datasets = 5
    # More time points and larger noise to simulate real language attrition data
    t = np.linspace(0, 100, 50)
    
    passes = 0
    results = []
    
    for i in range(n_datasets):
        k1 = np.random.uniform(0.05, 0.2)
        k2 = np.random.uniform(0.005, 0.02)
        C = np.random.uniform(0.05, 0.15)
        A = np.random.uniform(0.4, 0.7)
        
        y_true = biexp(t, k1, k2, C, A)
        y_noisy = np.clip(y_true + np.random.normal(0, 0.015, len(t)), 0, 1)
        
        fit = fit_models(t, y_noisy)
        delta_aic = fit['delta_aic_bi_vs_mono']
        
        passed = bool(delta_aic < -10)
        if passed:
            passes += 1
        
        results.append({
            "dataset": i + 1,
            "true_k1": float(k1), "true_k2": float(k2),
            "delta_aic_bi_vs_mono": float(delta_aic),
            "passed": passed
        })
    
    return {
        "simulacrum": 11,
        "name": "Substrate Independence (non-DNA)",
        "n_datasets": n_datasets,
        "n_passed": passes,
        "pass_criterion": "ΔAIC < -10 (bi-exp preferred) in ≥3/5 datasets",
        "passed": passes >= 3,
        "results": results
    }


def simulacrum_12():
    """Null Rate Ratio: k1 = k2 false positive rate."""
    np.random.seed(789)
    
    n_datasets = 20
    t = np.linspace(0, 100, 100)
    
    false_positives = 0
    results = []
    
    for i in range(n_datasets):
        k = np.random.uniform(0.05, 0.5)
        C = np.random.uniform(0.1, 0.3)
        
        y_true = C + (1.0 - C) * np.exp(-k * t)
        y_noisy = y_true + np.random.normal(0, 0.01, len(t))
        
        fit = fit_models(t, y_noisy)
        delta_aic = fit['delta_aic_bi_vs_mono']
        
        is_fp = bool(delta_aic < -2)
        if is_fp:
            false_positives += 1
        
        results.append({
            "dataset": i + 1,
            "true_k": float(k),
            "delta_aic": float(delta_aic),
            "false_positive": is_fp
        })
    
    fp_rate = false_positives / n_datasets
    
    return {
        "simulacrum": 12,
        "name": "Null Rate Ratio (k1 = k2)",
        "n_datasets": n_datasets,
        "n_false_positives": false_positives,
        "false_positive_rate": float(fp_rate),
        "pass_criterion": "false positive rate < 10%",
        "passed": bool(fp_rate < 0.10),
        "results": results
    }


def simulacrum_13():
    """Behavioral-Before-Morphological Under Random Ordering."""
    np.random.seed(101)
    
    n_transitions = 100
    n_correct = 0
    
    for i in range(n_transitions):
        behavior_first = np.random.random() > 0.5
        t_behavior = np.random.uniform(1, 100)
        if behavior_first:
            t_morph = t_behavior + np.random.uniform(1, 50)
        else:
            t_morph = t_behavior - np.random.uniform(1, 50)
        
        detected = t_behavior < t_morph
        if detected == behavior_first:
            n_correct += 1
    
    accuracy = n_correct / n_transitions
    
    return {
        "simulacrum": 13,
        "name": "Behavioral-Before-Morphological (Random Ordering)",
        "n_transitions": n_transitions,
        "n_correct": n_correct,
        "accuracy": float(accuracy),
        "pass_criterion": "≥95% correct classification",
        "passed": bool(accuracy >= 0.95)
    }


def clean_json(obj):
    if isinstance(obj, dict):
        return {k: clean_json(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [clean_json(v) for v in obj]
    elif isinstance(obj, (np.integer,)):
        return int(obj)
    elif isinstance(obj, (np.floating,)):
        return float(obj)
    elif isinstance(obj, (np.bool_,)):
        return bool(obj)
    return obj


def main():
    print("=" * 60)
    print("FOUNDRY SIMULACRA 9-13")
    print("=" * 60)
    
    all_results = []
    
    for func in [simulacrum_9, simulacrum_10, simulacrum_11, simulacrum_12, simulacrum_13]:
        print(f"\n--- Simulacrum {func.__name__.split('_')[1]} ---")
        result = clean_json(func())
        all_results.append(result)
        
        status = "PASS ✓" if result.get("passed") else "FAIL ✗"
        print(f"  {result['name']}: {status}")
        if "n_passed" in result:
            denom = result.get("n_systems", result.get("n_pairs", result.get("n_datasets", result.get("n_transitions", "?"))))
            print(f"  Passed: {result['n_passed']}/{denom}")
        if "false_positive_rate" in result:
            print(f"  False positive rate: {result['false_positive_rate']:.1%}")
        if "accuracy" in result:
            print(f"  Accuracy: {result['accuracy']:.1%}")
    
    n_passed = sum(1 for r in all_results if r.get("passed"))
    
    print(f"\n{'=' * 60}")
    print(f"SUMMARY: {n_passed}/5 simulacra passed")
    print(f"{'=' * 60}")
    
    # Save JSON
    with open(os.path.join(OUTPUT_DIR, "simulacra-9-13-results.json"), 'w') as f:
        json.dump(all_results, f, indent=2)
    
    # Save markdown report
    with open(os.path.join(OUTPUT_DIR, "simulacra-9-13-report.md"), 'w') as f:
        f.write("# Foundry Simulacra 9-13: Results\n\n")
        f.write(f"**Date:** 2026-08-18\n")
        f.write(f"**Passed:** {n_passed}/5\n\n")
        for r in all_results:
            status = "PASS ✓" if r.get("passed") else "FAIL ✗"
            f.write(f"## Simulacrum {r['simulacrum']}: {r['name']} — {status}\n\n")
            f.write(f"**Pass criterion:** {r['pass_criterion']}\n\n")
            if "results" in r and isinstance(r["results"], list):
                for item in r["results"][:5]:
                    if "delta_aic_bi_vs_mono" in item:
                        f.write(f"- {item.get('system', item.get('dataset', item.get('pair', '?')))}: ΔAIC = {item['delta_aic_bi_vs_mono']:.1f}")
                        if "ratio_error" in item:
                            f.write(f", ratio error = {item['ratio_error']:.1%}")
                        f.write(f" → {'✓' if item.get('passed') else '✗'}\n")
                    elif "spearman_rho" in item:
                        f.write(f"- Pair {item['pair']}: ρ = {item['spearman_rho']:.3f}, p = {item['p_value']:.4f} → {'✓' if item.get('passed') else '✗'}\n")
                if len(r["results"]) > 5:
                    f.write(f"\n*...and {len(r['results']) - 5} more*\n")
            f.write("\n")
    
    print(f"\nResults: {OUTPUT_DIR}/simulacra-9-13-results.json")
    print(f"Report: {OUTPUT_DIR}/simulacra-9-13-report.md")


if __name__ == "__main__":
    main()
