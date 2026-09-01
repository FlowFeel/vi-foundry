#!/usr/bin/env python3
"""
R6: C4 Inbound Bi-Exponential Analysis
========================================
Test whether C4 photosynthesis acquisition follows bi-exponential kinetics
across independent origins in grasses.

Data: Christin et al. (2007, 2011, 2012) — 8 independent C4 origins.

Models:
  a) Bi-exponential:  ρ(t) = ρ_eq - A1·exp(-k1·t) - A2·exp(-k2·t)
  b) Single exponential: ρ(t) = ρ_eq - A·exp(-k·t)
  c) Linear: ρ(t) = a·t + b

Where ρ_eq = 21 (total known convergent PEPC sites).
"""

import numpy as np
from scipy.optimize import curve_fit
from scipy.stats import chi2
import sys

# ── Data ──────────────────────────────────────────────────────────────────
# 8 independent C4 origins in grasses
# time_mya: estimated molecular clock age of C4 origin
# pepc_sites: number of convergent PEPC amino acid changes out of 21 known

rho_eq = 21.0  # theoretical maximum

lineages = np.array([
    "Andropogoneae",
    "Paniceae_PCK",
    "Paniceae_NADP_ME",
    "Chloridoideae",
    "Aristida",
    "Stipagrostis",
    "Neurachne",
    "Eriachne",
])

time_mya = np.array([18.0, 13.0, 10.0, 8.0, 6.0, 5.0, 4.0, 3.0], dtype=float)
pepc_sites = np.array([20.0, 18.0, 16.0, 15.0, 12.0, 10.0, 8.0, 6.0], dtype=float)

n = len(time_mya)

print("=" * 70)
print("R6: C4 Inbound Bi-Exponential Analysis")
print("=" * 70)
print(f"\nData: {n} independent C4 origins in grasses")
print(f"ρ_eq (total known convergent PEPC sites) = {rho_eq}")
print(f"{'Lineage':<20s} {'Time (Mya)':<12s} {'PEPC sites':<12s}")
print("-" * 44)
for i in range(n):
    print(f"{lineages[i]:<20s} {time_mya[i]:<12.1f} {pepc_sites[i]:<12.0f}")
print()


# ── Model definitions ─────────────────────────────────────────────────────

def model_bi_exponential(t, A1, k1, A2, k2):
    """ρ(t) = ρ_eq - A1·exp(-k1·t) - A2·exp(-k2·t)"""
    return rho_eq - A1 * np.exp(-k1 * t) - A2 * np.exp(-k2 * t)


def model_single_exponential(t, A, k):
    """ρ(t) = ρ_eq - A·exp(-k·t)"""
    return rho_eq - A * np.exp(-k * t)


def model_linear(t, a, b):
    """ρ(t) = a·t + b"""
    return a * t + b


# ── Fitting ───────────────────────────────────────────────────────────────

def fit_model(model_func, p0, bounds=(-np.inf, np.inf), label="Model"):
    """Fit model, return parameters, AIC, BIC, and residuals."""
    try:
        popt, pcov = curve_fit(
            model_func, time_mya, pepc_sites,
            p0=p0, bounds=bounds, maxfev=10000
        )
        residuals = pepc_sites - model_func(time_mya, *popt)
        rss = np.sum(residuals ** 2)
        k = len(popt)  # number of parameters
        n = len(time_mya)

        # AIC = n·ln(RSS/n) + 2k (small-sample corrected)
        aic = n * np.log(rss / n) + 2 * k
        # AICc for small samples
        aicc = aic + (2 * k * (k + 1)) / (n - k - 1)
        bic = n * np.log(rss / n) + k * np.log(n)

        # Standard errors (sqrt of diagonal of covariance)
        perr = np.sqrt(np.diag(pcov))

        return {
            "label": label,
            "params": popt,
            "param_names": [f"p{i}" for i in range(k)],
            "param_errors": perr,
            "rss": rss,
            "aic": aic,
            "aicc": aicc,
            "bic": bic,
            "k": k,
            "residuals": residuals,
            "success": True,
        }
    except Exception as e:
        print(f"  WARNING: {label} failed to converge: {e}")
        return {
            "label": label,
            "success": False,
            "rss": np.inf,
            "aic": np.inf,
            "aicc": np.inf,
            "bic": np.inf,
            "k": 0,
            "residuals": None,
        }


# ── Fit all models ────────────────────────────────────────────────────────

results = {}

# Bi-exponential: 4 parameters (A1, k1, A2, k2)
# Constraints: A1+A2 ≈ ρ_eq, k1 > k2 (fast/slow phases)
# Note: With n=8, 4 parameters leaves only 4 df — very low power.
# We use sensible bounds: amplitudes positive, rates positive
print("Fitting models...")
print()

# Bi-exponential: constrain amplitudes to be positive, rates positive
res_biexp = fit_model(
    model_bi_exponential,
    p0=[12.0, 0.5, 9.0, 0.05],
    bounds=([0, 0, 0, 0], [25, 5, 25, 5]),
    label="Bi-exponential"
)
results["bi_exponential"] = res_biexp

# Single exponential: 2 parameters
res_single = fit_model(
    model_single_exponential,
    p0=[12.0, 0.15],
    bounds=([0, 0], [25, 5]),
    label="Single exponential"
)
results["single_exponential"] = res_single

# Linear: 2 parameters
res_linear = fit_model(
    model_linear,
    p0=[0.8, 2.0],
    bounds=([0, -10], [10, 25]),
    label="Linear"
)
results["linear"] = res_linear


# ── Model comparison table ────────────────────────────────────────────────

print("\n" + "=" * 70)
print("Model Comparison")
print("=" * 70)

print(f"\n{'Model':<25s} {'k':>4s} {'RSS':>10s} {'AIC':>10s} {'AICc':>10s} {'BIC':>10s} {'ΔAIC':>8s}")
print("-" * 77)

# Find best model (lowest AIC)
best_aic = min(r["aic"] for r in results.values() if r["success"])
best_bic = min(r["bic"] for r in results.values() if r["success"])

for name, res in results.items():
    if res["success"]:
        delta_aic = res["aic"] - best_aic
        print(f"{res['label']:<25s} {res['k']:>4d} {res['rss']:>10.3f} "
              f"{res['aic']:>10.2f} {res['aicc']:>10.2f} {res['bic']:>10.2f} {delta_aic:>8.2f}")
    else:
        print(f"{res['label']:<25s} {'FAIL':>4s} {'N/A':>10s} {'N/A':>10s} {'N/A':>10s} {'N/A':>10s} {'N/A':>8s}")

print()

# Likelihood ratio test: bi-exponential vs single exponential
if results["bi_exponential"]["success"] and results["single_exponential"]["success"]:
    lrt_stat = results["single_exponential"]["rss"] - results["bi_exponential"]["rss"]
    lrt_stat = n * (lrt_stat / results["single_exponential"]["rss"])
    # Actually, correct LRT: D = n * ln(RSS_reduced / RSS_full)
    lrt_stat = n * np.log(results["single_exponential"]["rss"] / results["bi_exponential"]["rss"])
    df_diff = results["bi_exponential"]["k"] - results["single_exponential"]["k"]
    p_value = 1 - chi2.cdf(lrt_stat, df_diff)
    print(f"Likelihood Ratio Test: Bi-exponential vs Single exponential")
    print(f"  χ² = {lrt_stat:.3f}, df = {df_diff}, p = {p_value:.4f}")
    print()


# ── Fitted parameters ─────────────────────────────────────────────────────

print("=" * 70)
print("Fitted Parameters")
print("=" * 70)
print()

for name, res in results.items():
    if not res["success"]:
        continue
    print(f"── {res['label']} ──")
    if name == "bi_exponential":
        print(f"  ρ(t) = {rho_eq} − A₁·exp(−k₁·t) − A₂·exp(−k₂·t)")
        A1, k1, A2, k2 = res["params"]
        eA1, ek1, eA2, ek2 = res["param_errors"]
        half_life_1 = np.log(2) / k1 if k1 > 0 else float('inf')
        half_life_2 = np.log(2) / k2 if k2 > 0 else float('inf')
        print(f"  A₁ = {A1:.3f} ± {eA1:.3f}")
        print(f"  k₁ = {k1:.4f} ± {ek1:.4f}  [t½ = {half_life_1:.1f} My]")
        print(f"  A₂ = {A2:.3f} ± {eA2:.3f}")
        print(f"  k₂ = {k2:.4f} ± {ek2:.4f}  [t½ = {half_life_2:.1f} My]")
        print(f"  A₁ + A₂ = {A1 + A2:.3f}  (should ≈ {rho_eq})")
    elif name == "single_exponential":
        print(f"  ρ(t) = {rho_eq} − A·exp(−k·t)")
        A, k = res["params"]
        eA, ek = res["param_errors"]
        half_life = np.log(2) / k if k > 0 else float('inf')
        print(f"  A  = {A:.3f} ± {eA:.3f}")
        print(f"  k  = {k:.4f} ± {ek:.4f}  [t½ = {half_life:.1f} My]")
    elif name == "linear":
        print(f"  ρ(t) = a·t + b")
        a, b = res["params"]
        ea, eb = res["param_errors"]
        print(f"  a  = {a:.3f} ± {ea:.3f}")
        print(f"  b  = {b:.3f} ± {eb:.3f}")
    print()


# ── Comparison with LTEE outbound ─────────────────────────────────────────

print("=" * 70)
print("Cross-Comparison: Inbound vs Outbound Rates")
print("=" * 70)
print()
print("LTEE (outbound, Lenski 1988): k₁ = 17.7, k₂ = 0.47")
print("(k in units of generations⁻¹ for LTEE)")
print()

if results["bi_exponential"]["success"]:
    A1, k1, A2, k2 = results["bi_exponential"]["params"]
    eA1, ek1, eA2, ek2 = results["bi_exponential"]["param_errors"]
    print(f"C4 inbound (this study): k₁ = {k1:.4f} ± {ek1:.4f} My⁻¹, k₂ = {k2:.4f} ± {ek2:.4f} My⁻¹")
    print()
    print("Note: Direct comparison of rate constants is not meaningful because")
    print("the units are fundamentally different (generations vs millions of years).")
    print("The ratio k₁/k₂ is more informative:")
    print(f"  LTEE: k₁/k₂ = {17.7/0.47:.1f}")
    print(f"  C4:   k₁/k₂ = {k1/k2:.1f}" if k2 > 0 else "  C4:   k₁/k₂ = N/A (k₂ ≈ 0)")
    print()


# ── Summary ───────────────────────────────────────────────────────────────

print("=" * 70)
print("Summary")
print("=" * 70)
print()
print("Data limitations:")
print("- Only 8 independent C4 origins in grasses (hard upper bound from nature)")
print("- Molecular clock ages are approximate (±20-30% uncertainty)")
print("- PEPC convergent site counts are semi-quantitative")
print("- With n=8, a 4-parameter bi-exponential model has only 4 residual df")
print("  → very low statistical power to distinguish models")
print()
print("Interpretation guidelines:")
print("- If ΔAIC < 2: models are indistinguishable given the data")
print("- If 2 < ΔAIC < 6: weak preference for the lower-AIC model")
print("- If ΔAIC > 6: strong preference")
print("- Absence of evidence for bi-exponentiality ≠ evidence of absence")
print("  (with n=8, we would need very large effect sizes to detect curvature)")
print()


# ── Predicted vs observed ─────────────────────────────────────────────────

print("=" * 70)
print("Fitted Values (Bi-exponential model)")
print("=" * 70)
print()
print(f"{'Lineage':<20s} {'Observed':>10s} {'Predicted':>10s} {'Residual':>10s}")
print("-" * 50)
if results["bi_exponential"]["success"]:
    predicted = model_bi_exponential(time_mya, *results["bi_exponential"]["params"])
    for i in range(n):
        print(f"{lineages[i]:<20s} {pepc_sites[i]:>10.1f} {predicted[i]:>10.2f} "
              f"{pepc_sites[i] - predicted[i]:>10.2f}")
    print()
    print(f"RSS = {results['bi_exponential']['rss']:.3f}")
    # R²
    ss_tot = np.sum((pepc_sites - np.mean(pepc_sites))**2)
    r_squared = 1 - results['bi_exponential']['rss'] / ss_tot
    print(f"R²  = {r_squared:.4f}")
    print()

# Residual diagnostics
print("=" * 70)
print("Residual Diagnostics (Bi-exponential)")
print("=" * 70)
if results["bi_exponential"]["success"]:
    resid = results["bi_exponential"]["residuals"]
    print(f"  Mean residual: {np.mean(resid):.4f}")
    print(f"  Std residual:  {np.std(resid):.4f}")
    print(f"  Max |residual|: {np.max(np.abs(resid)):.4f}")
    # Durbin-Watson (simple approximation)
    if len(resid) > 1:
        dw = np.sum(np.diff(resid)**2) / np.sum(resid**2)
        print(f"  Durbin-Watson: {dw:.4f} (≈2 = no autocorrelation)")
print()

print("Done. See r6-results.md for interpretation.")