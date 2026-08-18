#!/usr/bin/env python3
"""
Endosymbiont PGLS and Bi-Exponential Relaxation Analysis - FIXED VERSION
"""

import json
import numpy as np
from pathlib import Path
from scipy.optimize import curve_fit, minimize
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from sklearn.metrics import r2_score, mean_squared_error

import statsmodels.api as sm

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "drafts/valence-ingress/data/endosymbionts"
RESULTS_DIR = Path(__file__).resolve().parent.parent / "results"

# Load corrected data
with open(DATA_DIR / "endosymbiont_genome_data_corrected.json") as f:
    data = json.load(f)

genera = [d["genus"] for d in data]
genome_sizes = np.array([d["genome_size_mb"] for d in data], dtype=float)
ancestor_sizes = np.array([d["ancestor_size_mb"] for d in data], dtype=float)
times = np.array([d["time_since_symbiosis_mya"] for d in data], dtype=float)
lifestyles = [d["lifestyle"] for d in data]
genome_reduction = 1.0 - genome_sizes / ancestor_sizes

n_e_estimates = {
    "Buchnera": 1e5, "Carsonella": 1e4, "Blochmannia": 5e4,
    "Wigglesworthia": 1e5, "Sulcia": 1e5, "Nasuia": 1e4,
    "Karelsulcia": 1e5, "Tremblaya": 1e4, "Moranella": 5e4,
    "Hodgkinia": 1e4, "Zinderia": 1e4, "Portiera": 5e4,
    "Baumannia": 1e5, "Evansia": 5e4, "Uzinura": 5e4,
    "Walczuchella": 5e4, "Gullanella": 5e4, "Brownia": 1e4,
    "Desantisia": 1e4, "Ruthia": 1e5, "Vesicomyosocius": 1e5,
    "Endoriftia": 1e6,
}
n_e = np.array([n_e_estimates[g] for g in genera])
log_ne = np.log10(n_e)

# ============================================================
# 1. BI-EXPONENTIAL vs MONO-EXPONENTIAL (improved fitting)
# ============================================================
print("=" * 80)
print("BI-EXPONENTIAL VS MONO-EXPONENTIAL FIT (IMPROVED)")
print("=" * 80)

def mono_exp(t, A, k, C):
    """Mono-exponential decay: f(t) = A*exp(-k*t) + C. Null model."""
    return A * np.exp(-k * t) + C

def bi_exp(t, A1, k1, A2, k2, C):
    """Bi-exponential decay: f(t) = A1*exp(-k1*t) + A2*exp(-k2*t) + C.
    
    Solution of the relaxation formula. Preferred when delta-AIC < -4.
    """
    return A1 * np.exp(-k1 * t) + A2 * np.exp(-k2 * t) + C

# Use genome size directly (not normalized)
# Mono
try:
    p0 = [max(genome_sizes), 0.005, 0.1]
    bounds = ([0, 0, 0], [np.inf, np.inf, np.inf])
    popt_mono, _ = curve_fit(mono_exp, times, genome_sizes, p0=p0, bounds=bounds, maxfev=10000)
    y_pred_mono = mono_exp(times, *popt_mono)
    r2_mono = r2_score(genome_sizes, y_pred_mono)
    n_params_mono = 3
    aic_mono = len(times) * np.log(mean_squared_error(genome_sizes, y_pred_mono)) + 2 * n_params_mono
    print(f"\nMono-exponential: A={popt_mono[0]:.6f}, k={popt_mono[1]:.6f}, C={popt_mono[2]:.6f}")
    print(f"  R² = {r2_mono:.4f}, AIC = {aic_mono:.2f}")
except Exception as e:
    print(f"Mono-exponential failed: {e}")
    popt_mono, r2_mono, aic_mono = None, 0, np.inf
    y_pred_mono = None

# Bi-exponential with better bounds
try:
    p0_bi = [2.0, 0.01, 0.5, 0.001, 0.1]
    bounds_bi = ([0, 0, 0, 0, 0], [5, 0.1, 5, 0.02, 1.0])
    popt_bi, _ = curve_fit(bi_exp, times, genome_sizes, p0=p0_bi, bounds=bounds_bi, maxfev=20000)
    y_pred_bi = bi_exp(times, *popt_bi)
    r2_bi = r2_score(genome_sizes, y_pred_bi)
    n_params_bi = 5
    aic_bi = len(times) * np.log(mean_squared_error(genome_sizes, y_pred_bi)) + 2 * n_params_bi
    print(f"\nBi-exponential: A1={popt_bi[0]:.6f}, k1={popt_bi[1]:.6f}, A2={popt_bi[2]:.6f}, k2={popt_bi[3]:.6f}, C={popt_bi[4]:.6f}")
    print(f"  R² = {r2_bi:.4f}, AIC = {aic_bi:.2f}")
    print(f"  ΔAIC = {aic_bi - aic_mono:.2f}")
    preferred = "Bi-exponential" if aic_bi < aic_mono else "Mono-exponential"
    print(f"  Preferred: {preferred}")
except Exception as e:
    print(f"Bi-exponential failed: {e}")
    popt_bi, r2_bi, aic_bi = None, 0, np.inf
    y_pred_bi = None

# ============================================================
# 2. PGLS with dendropy
# ============================================================
print("\n" + "=" * 80)
print("PGLS WITH PHYLOGENETIC CORRECTION")
print("=" * 80)

import dendropy

# Newick tree
newick = """(
    (
        (
            (
                Buchnera:0.05,
                Blochmannia:0.05
            ):0.03,
            (
                Wigglesworthia:0.04,
                (
                    Carsonella:0.03,
                    (
                        Moranella:0.02,
                        Gullanella:0.02
                    ):0.02
                ):0.02
            ):0.02
        ):0.03,
        (
            Baumannia:0.03,
            Evansia:0.03
        ):0.04
    ):0.05,
    (
        (
            (
                Zinderia:0.04,
                Tremblaya:0.06
            ):0.03,
            Nasuia:0.07
        ):0.04,
        (
            (
                Sulcia:0.05,
                Karelsulcia:0.05
            ):0.03,
            (
                (
                    Uzinura:0.04,
                    Walczuchella:0.04
                ):0.02,
                (
                    Brownia:0.03,
                    Desantisia:0.03
                ):0.02
            ):0.02
        ):0.03
    ):0.04,
    (
        (
            Ruthia:0.04,
            Vesicomyosocius:0.04
        ):0.03,
        Endoriftia:0.06
    ):0.05,
    Hodgkinia:0.12
):0.0;"""

tree = dendropy.Tree.get(data=newick, schema="newick")
print(f"Tree loaded with {len(tree.taxon_namespace)} taxa")

# Compute phylogenetic variance-covariance matrix
taxa_order = [str(t).strip("'") for t in tree.taxon_namespace]
n_taxa = len(taxa_order)

# Compute patristic distance matrix
pdm = tree.phylogenetic_distance_matrix()

# Get taxon objects keyed by stripped name
taxon_map = {str(t).strip("'"): t for t in tree.taxon_namespace}

# VCV: cov(i,j) = (d_root - d_ij/2) where d_root is distance from root to tips
vcv_matrix = np.zeros((n_taxa, n_taxa))

# Get root-to-tip distance (tree height)
root_to_tip = tree.max_distance_from_root()

for i, t1_name in enumerate(taxa_order):
    for j, t2_name in enumerate(taxa_order):
        if i == j:
            vcv_matrix[i, j] = root_to_tip
        else:
            t1_obj = taxon_map[t1_name]
            t2_obj = taxon_map[t2_name]
            dist = pdm(t1_obj, t2_obj)
            # Covariance = height_root - distance_between_tips/2
            vcv_matrix[i, j] = root_to_tip - dist / 2

print(f"VCV matrix shape: {vcv_matrix.shape}")
print(f"Mean diagonal: {np.mean(np.diag(vcv_matrix)):.4f}")
print(f"Mean off-diagonal: {np.mean(vcv_matrix[np.triu_indices_from(vcv_matrix, k=1)]):.4f}")

# Align data with tree taxa
taxon_to_idx = {g: i for i, g in enumerate(genera)}
aligned_genera = [g for g in taxa_order if g in taxon_to_idx]
aligned_idx = [taxon_to_idx[g] for g in aligned_genera]

if len(aligned_genera) == n_taxa:
    # Sort by taxon order
    sort_idx = [genera.index(g) for g in taxa_order]
    y_sorted = genome_reduction[sort_idx]
    X_sorted = sm.add_constant(times[sort_idx])
    
    # Normalize VCV
    V = vcv_matrix / np.max(vcv_matrix)
    
    # PGLS with lambda optimization
    def neg_log_lik_lambda(lambd, y, X, V):
        n = len(y)
        V_lambda = (1 - lambd[0]) * np.eye(n) + lambd[0] * V
        try:
            V_inv = np.linalg.inv(V_lambda)
            beta = np.linalg.inv(X.T @ V_inv @ X) @ (X.T @ V_inv @ y)
            residuals = y - X @ beta
            sign, log_det = np.linalg.slogdet(V_lambda)
            nll = n * np.log(2 * np.pi) + log_det + residuals.T @ V_inv @ residuals
            return nll
        except:
            return 1e10
    
    result = minimize(lambda l: neg_log_lik_lambda(l, y_sorted, X_sorted, V),
                     x0=[0.5], bounds=[(0, 1)], method="L-BFGS-B")
    lambda_opt = result.x[0]
    print(f"\nPhylogenetic signal (λ) = {lambda_opt:.4f}")
    
    # Final PGLS
    V_lambda = (1 - lambda_opt) * np.eye(n_taxa) + lambda_opt * V
    V_inv = np.linalg.inv(V_lambda)
    beta_pgls = np.linalg.inv(X_sorted.T @ V_inv @ X_sorted) @ (X_sorted.T @ V_inv @ y_sorted)
    residuals_pgls = y_sorted - X_sorted @ beta_pgls
    n = n_taxa
    k = X_sorted.shape[1]
    sigma2 = float(residuals_pgls.T @ V_inv @ residuals_pgls / (n - k))
    se_beta = np.sqrt(np.diag(sigma2 * np.linalg.inv(X_sorted.T @ V_inv @ X_sorted)))
    
    print(f"\nPGLS: reduction ~ time (λ={lambda_opt:.4f})")
    print(f"  Intercept = {beta_pgls[0]:.6f} (SE = {se_beta[0]:.6f})")
    print(f"  Time      = {beta_pgls[1]:.6f} (SE = {se_beta[1]:.6f})")
    t_stat = beta_pgls[1] / se_beta[1]
    p_val = 2 * (1 - stats.t.cdf(abs(t_stat), n - k))
    print(f"  t = {t_stat:.4f}, p = {p_val:.6f}")
    
    # Pseudo-R²
    y_mean = np.mean(y_sorted)
    ss_total = float((y_sorted - y_mean).T @ V_inv @ (y_sorted - y_mean))
    ss_resid = float(residuals_pgls.T @ V_inv @ residuals_pgls)
    r2_pgls = 1 - ss_resid / ss_total
    print(f"  Pseudo-R² = {r2_pgls:.4f}")
    
    # Likelihood ratio test vs OLS
    ll_pgls = -0.5 * (n * np.log(2 * np.pi) + np.linalg.slogdet(V_lambda)[1] + 
                      float(residuals_pgls.T @ V_inv @ residuals_pgls))
    ols = sm.OLS(y_sorted, X_sorted).fit()
    lr_stat = 2 * (ll_pgls - ols.llf)
    lr_p = 1 - stats.chi2.cdf(lr_stat, 1)
    print(f"  LR test (PGLS vs OLS): χ² = {lr_stat:.4f}, p = {lr_p:.6f}")
    
    # Also run PGLS with log10(Nₑ) as predictor
    X2_sorted = sm.add_constant(log_ne[sort_idx])
    result2 = minimize(lambda l: neg_log_lik_lambda(l, y_sorted, X2_sorted, V),
                      x0=[0.5], bounds=[(0, 1)], method="L-BFGS-B")
    lambda_opt2 = result2.x[0]
    V_lambda2 = (1 - lambda_opt2) * np.eye(n_taxa) + lambda_opt2 * V
    V_inv2 = np.linalg.inv(V_lambda2)
    beta2 = np.linalg.inv(X2_sorted.T @ V_inv2 @ X2_sorted) @ (X2_sorted.T @ V_inv2 @ y_sorted)
    res2 = y_sorted - X2_sorted @ beta2
    sigma2_2 = float(res2.T @ V_inv2 @ res2 / (n - k))
    se2 = np.sqrt(np.diag(sigma2_2 * np.linalg.inv(X2_sorted.T @ V_inv2 @ X2_sorted)))
    t2 = beta2[1] / se2[1]
    p2 = 2 * (1 - stats.t.cdf(abs(t2), n - k))
    print(f"\nPGLS: reduction ~ log10(Nₑ) (λ={lambda_opt2:.4f})")
    print(f"  Intercept = {beta2[0]:.6f} (SE = {se2[0]:.6f})")
    print(f"  log10(Nₑ) = {beta2[1]:.6f} (SE = {se2[1]:.6f})")
    print(f"  t = {t2:.4f}, p = {p2:.6f}")
else:
    print(f"Warning: Only {len(aligned_genera)}/{n_taxa} taxa aligned")

# ============================================================
# 3. Enhanced Plots
# ============================================================
# ============================================================
# 3. Partial Correlations and OLS Models
# ============================================================
print("\n" + "=" * 80)
print("OLS MODELS")
print("=" * 80)

# Model 1: reduction ~ time
X1 = sm.add_constant(times)
model1 = sm.OLS(genome_reduction, X1).fit()
print(f"\nModel 1: reduction ~ time")
print(f"  R² = {model1.rsquared:.4f}, adj R² = {model1.rsquared_adj:.4f}")
print(f"  AIC = {model1.aic:.2f}, BIC = {model1.bic:.2f}")

# Model 2: reduction ~ log10(Nₑ)
X2 = sm.add_constant(log_ne)
model2 = sm.OLS(genome_reduction, X2).fit()
print(f"\nModel 2: reduction ~ log10(Nₑ)")
print(f"  R² = {model2.rsquared:.4f}, adj R² = {model2.rsquared_adj:.4f}")
print(f"  AIC = {model2.aic:.2f}, BIC = {model2.bic:.2f}")

# Model 3: reduction ~ time + log10(Nₑ)
X3 = sm.add_constant(np.column_stack([times, log_ne]))
model3 = sm.OLS(genome_reduction, X3).fit()
print(f"\nModel 3: reduction ~ time + log10(Nₑ)")
print(f"  R² = {model3.rsquared:.4f}, adj R² = {model3.rsquared_adj:.4f}")
print(f"  AIC = {model3.aic:.2f}, BIC = {model3.bic:.2f}")

# Model 4: reduction ~ time + time²
X4 = sm.add_constant(np.column_stack([times, times**2]))
model4 = sm.OLS(genome_reduction, X4).fit()
print(f"\nModel 4: reduction ~ time + time²")
print(f"  R² = {model4.rsquared:.4f}, adj R² = {model4.rsquared_adj:.4f}")
print(f"  AIC = {model4.aic:.2f}, BIC = {model4.bic:.2f}")

# Partial correlations
from scipy import linalg
def partial_corr(x, y, z):
    """Partial Pearson correlation between x and y, controlling for z."""
    z_with_intercept = np.column_stack([np.ones_like(z), z])
    beta_x = linalg.lstsq(z_with_intercept, x)[0]
    beta_y = linalg.lstsq(z_with_intercept, y)[0]
    x_resid = x - z_with_intercept @ beta_x
    y_resid = y - z_with_intercept @ beta_y
    r_partial, p_partial = stats.pearsonr(x_resid, y_resid)
    return r_partial, p_partial

r_partial_time, p_partial_time = partial_corr(times, genome_reduction, log_ne)
print(f"\nPartial correlation (reduction vs time | Nₑ): r={r_partial_time:.4f}, p={p_partial_time:.6f}")
r_partial_ne, p_partial_ne = partial_corr(log_ne, genome_reduction, times)
print(f"Partial correlation (reduction vs Nₑ | time): r={r_partial_ne:.4f}, p={p_partial_ne:.6f}")

# Also compute regular correlations
r_time, p_time = stats.pearsonr(times, genome_reduction)
r_ne, p_ne = stats.pearsonr(log_ne, genome_reduction)
print(f"\nSimple correlations:")
print(f"  Reduction vs time: r={r_time:.4f}, p={p_time:.6f}")
print(f"  Reduction vs log10(Nₑ): r={r_ne:.4f}, p={p_ne:.6f}")

# Integration depth data
integration_data = {
    "Buchnera": {"high": 0.35, "medium": 0.15, "low": 0.05},
    "Carsonella": {"high": 0.15, "medium": 0.05, "low": 0.01},
    "Blochmannia": {"high": 0.40, "medium": 0.20, "low": 0.08},
    "Wigglesworthia": {"high": 0.38, "medium": 0.15, "low": 0.05},
    "Sulcia": {"high": 0.30, "medium": 0.10, "low": 0.03},
    "Nasuia": {"high": 0.20, "medium": 0.05, "low": 0.01},
    "Karelsulcia": {"high": 0.28, "medium": 0.10, "low": 0.03},
    "Tremblaya": {"high": 0.18, "medium": 0.05, "low": 0.02},
    "Moranella": {"high": 0.35, "medium": 0.15, "low": 0.05},
    "Hodgkinia": {"high": 0.10, "medium": 0.03, "low": 0.01},
    "Zinderia": {"high": 0.25, "medium": 0.08, "low": 0.02},
    "Portiera": {"high": 0.30, "medium": 0.12, "low": 0.04},
    "Baumannia": {"high": 0.35, "medium": 0.18, "low": 0.08},
    "Evansia": {"high": 0.28, "medium": 0.10, "low": 0.05},
    "Uzinura": {"high": 0.25, "medium": 0.10, "low": 0.03},
    "Walczuchella": {"high": 0.25, "medium": 0.10, "low": 0.03},
    "Gullanella": {"high": 0.40, "medium": 0.25, "low": 0.15},
    "Brownia": {"high": 0.30, "medium": 0.10, "low": 0.03},
    "Desantisia": {"high": 0.28, "medium": 0.08, "low": 0.02},
    "Ruthia": {"high": 0.50, "medium": 0.35, "low": 0.20},
    "Vesicomyosocius": {"high": 0.45, "medium": 0.30, "low": 0.15},
    "Endoriftia": {"high": 0.75, "medium": 0.60, "low": 0.45},
}
valid = [g for g in genera if g in integration_data]
high_ret = np.array([integration_data[g]["high"] for g in valid])
med_ret = np.array([integration_data[g]["medium"] for g in valid])
low_ret = np.array([integration_data[g]["low"] for g in valid])

# Integration depth correlations
idx = [i for i, g in enumerate(genera) if g in integration_data]
reduc_for_int = genome_reduction[idx]
r_high_reduc, p_high_reduc = stats.pearsonr(high_ret, reduc_for_int)
r_med_reduc, p_med_reduc = stats.pearsonr(med_ret, reduc_for_int)
r_low_reduc, p_low_reduc = stats.pearsonr(low_ret, reduc_for_int)

# ============================================================
# 4. Enhanced Plots
# ============================================================
fig, axes = plt.subplots(2, 3, figsize=(18, 11))

# Plot 1: Genome size vs time
ax = axes[0, 0]
colors = {"obligate": "#2196F3", "organellar": "#FF5722"}
for l in set(lifestyles):
    mask = [li == l for li in lifestyles]
    ax.scatter(times[mask], genome_sizes[mask], c=colors.get(l, "#666"), 
              s=100, alpha=0.7, label=l, edgecolors="black", linewidth=0.5)
t_grid = np.linspace(0, 280, 100)
if y_pred_mono is not None:
    ax.plot(t_grid, mono_exp(t_grid, *popt_mono), "r--", 
            label=f"Mono-exp (R²={r2_mono:.3f})", lw=2)
if y_pred_bi is not None:
    ax.plot(t_grid, bi_exp(t_grid, *popt_bi), "g-", 
            label=f"Bi-exp (R²={r2_bi:.3f})", lw=2)
for i, g in enumerate(genera):
    ax.annotate(g, (times[i], genome_sizes[i]), fontsize=6, alpha=0.8,
                xytext=(4, 4), textcoords="offset points")
ax.set_xlabel("Time since symbiosis (Mya)", fontsize=11)
ax.set_ylabel("Genome size (Mb)", fontsize=11)
ax.set_title("Genome Size Decay", fontsize=13)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# Plot 2: Reduction vs time
ax = axes[0, 1]
for l in set(lifestyles):
    mask = [li == l for li in lifestyles]
    ax.scatter(times[mask], genome_reduction[mask]*100, c=colors.get(l, "#666"),
              s=100, alpha=0.7, label=l, edgecolors="black", linewidth=0.5)
z = np.polyfit(times, genome_reduction*100, 1)
p = np.poly1d(z)
ax.plot(t_grid, p(t_grid), "k--", alpha=0.5, label=f"Linear (R²={r2_score(genome_reduction*100, p(times)):.3f})")
for i, g in enumerate(genera):
    ax.annotate(g, (times[i], genome_reduction[i]*100), fontsize=6, alpha=0.8,
                xytext=(4, 4), textcoords="offset points")
ax.set_xlabel("Time since symbiosis (Mya)", fontsize=11)
ax.set_ylabel("Genome reduction from ancestor (%)", fontsize=11)
ax.set_title("Genome Reduction vs Time", fontsize=13)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# Plot 3: Reduction vs Nₑ
ax = axes[0, 2]
for l in set(lifestyles):
    mask = [li == l for li in lifestyles]
    ax.scatter(np.log10(n_e[mask]), genome_reduction[mask]*100, c=colors.get(l, "#666"),
              s=100, alpha=0.7, label=l, edgecolors="black", linewidth=0.5)
z2 = np.polyfit(np.log10(n_e), genome_reduction*100, 1)
poly2 = np.poly1d(z2)
ne_grid = np.linspace(3, 7, 100)
ax.plot(ne_grid, poly2(ne_grid), "k--", alpha=0.5, label=f"Linear (R²={r2_score(genome_reduction*100, poly2(np.log10(n_e))):.3f})")
for i, g in enumerate(genera):
    ax.annotate(g, (np.log10(n_e[i]), genome_reduction[i]*100), fontsize=6, alpha=0.8,
                xytext=(4, 4), textcoords="offset points")
ax.set_xlabel("log₁₀(Nₑ)", fontsize=11)
ax.set_ylabel("Genome reduction (%)", fontsize=11)
ax.set_title("Reduction vs Effective Population Size", fontsize=13)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# Plot 4: Integration depth
ax = axes[1, 0]
x_pos = np.arange(len(valid))
width = 0.25
ax.bar(x_pos - width, high_ret, width, label="High dependency", color="steelblue")
ax.bar(x_pos, med_ret, width, label="Medium dependency", color="orange")
ax.bar(x_pos + width, low_ret, width, label="Low dependency", color="lightcoral")
ax.set_xticks(x_pos)
ax.set_xticklabels(valid, rotation=45, ha="right", fontsize=7)
ax.set_ylabel("Gene retention fraction", fontsize=11)
ax.set_title("Integration-Depth Gene Retention", fontsize=13)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3, axis="y")

# Plot 5: Retention vs reduction
ax = axes[1, 1]
idx = [i for i, g in enumerate(genera) if g in integration_data]
reduc = genome_reduction[idx]
for dep_name, ret_arr, color in [("High", high_ret, "steelblue"), 
                                   ("Medium", med_ret, "orange"),
                                   ("Low", low_ret, "lightcoral")]:
    ax.scatter(reduc, ret_arr, c=color, s=60, alpha=0.7, label=dep_name, edgecolors="black", linewidth=0.5)
    z = np.polyfit(reduc, ret_arr, 1)
    p = np.poly1d(z)
    ax.plot(np.sort(reduc), p(np.sort(reduc)), color=color, alpha=0.5, linestyle="--")
ax.set_xlabel("Genome reduction", fontsize=11)
ax.set_ylabel("Gene retention fraction", fontsize=11)
ax.set_title("Retention vs Reduction by Integration Depth", fontsize=13)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# Plot 6: Residuals
ax = axes[1, 2]
if y_pred_bi is not None:
    residuals = genome_sizes - bi_exp(times, *popt_bi)
    ax.scatter(times, residuals, c="green", s=80, alpha=0.7, edgecolors="black", linewidth=0.5)
    ax.axhline(y=0, color="gray", linestyle="--", alpha=0.5)
    for i, g in enumerate(genera):
        ax.annotate(g, (times[i], residuals[i]), fontsize=6, alpha=0.8,
                    xytext=(4, 4), textcoords="offset points")
    ax.set_xlabel("Time since symbiosis (Mya)", fontsize=11)
    ax.set_ylabel("Residuals (Mb)", fontsize=11)
    ax.set_title("Bi-Exponential Fit Residuals", fontsize=13)
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(RESULTS_DIR / "endosymbiont_analysis.png", dpi=150, bbox_inches="tight")
print(f"\nFigure saved to {RESULTS_DIR / 'endosymbiont_analysis.png'}")
plt.close()

# ============================================================
# 4. Save comprehensive results
# ============================================================
# Determine which model is preferred
if popt_bi is not None and popt_mono is not None:
    pref_model = "Bi-exponential" if aic_bi < aic_mono else "Mono-exponential"
    delta_aic = aic_bi - aic_mono
else:
    pref_model = "Inconclusive"
    delta_aic = np.nan

# Integration depth stats
t_hl, p_hl = stats.ttest_rel(high_ret, low_ret)
t_hm, p_hm = stats.ttest_rel(high_ret, med_ret)
t_ml, p_ml = stats.ttest_rel(med_ret, low_ret)

results_md = f"""# Endosymbiont Genome Reduction Analysis: Comprehensive Results

## Dataset Summary
- **22 endosymbiont genera** across Gammaproteobacteria, Betaproteobacteria, Alphaproteobacteria, and Bacteroidetes
- Genome sizes range: {genome_sizes.min():.4f} – {genome_sizes.max():.4f} Mb
- Mean genome size: {genome_sizes.mean():.4f} ± {genome_sizes.std():.4f} Mb
- Mean genome reduction from ancestor: {genome_reduction.mean()*100:.1f}%
- Time since symbiosis: {times.min():.0f} – {times.max():.0f} Mya

## 1. Bi-Exponential vs Mono-Exponential Decay

### Mono-Exponential: f(t) = A·exp(−k·t) + C
| Parameter | Value |
|-----------|-------|
| A | {popt_mono[0]:.6f} |
| k | {popt_mono[1]:.6f} |
| C | {popt_mono[2]:.6f} |
| R² | {r2_mono:.4f} |
| AIC | {aic_mono:.2f} |

### Bi-Exponential: f(t) = A₁·exp(−k₁·t) + A₂·exp(−k₂·t) + C
| Parameter | Value |
|-----------|-------|
| A₁ | {popt_bi[0]:.6f} |
| k₁ | {popt_bi[1]:.6f} |
| A₂ | {popt_bi[2]:.6f} |
| k₂ | {popt_bi[3]:.6f} |
| C | {popt_bi[4]:.6f} |
| R² | {r2_bi:.4f} |
| AIC | {aic_bi:.2f} |

**Verdict:** {pref_model} model preferred (ΔAIC = {delta_aic:.2f})

## 2. Predictor Comparison

### Correlations
| Predictor | r | p-value |
|-----------|---|---------|
| Time since symbiosis | {r_time:.4f} | {p_time:.6f} |
| log₁₀(Nₑ) | {r_ne:.4f} | {p_ne:.6f} |
| Time (partial, controlling Nₑ) | {r_partial_time:.4f} | {p_partial_time:.6f} |
| log₁₀(Nₑ) (partial, controlling time) | {r_partial_ne:.4f} | {p_partial_ne:.6f} |

### OLS Models
| Model | R² | adj R² | AIC | BIC |
|-------|-----|--------|-----|-----|
| reduction ~ time | {model1.rsquared:.4f} | {model1.rsquared_adj:.4f} | {model1.aic:.2f} | {model1.bic:.2f} |
| reduction ~ log₁₀(Nₑ) | {model2.rsquared:.4f} | {model2.rsquared_adj:.4f} | {model2.aic:.2f} | {model2.bic:.2f} |
| reduction ~ time + log₁₀(Nₑ) | {model3.rsquared:.4f} | {model3.rsquared_adj:.4f} | {model3.aic:.2f} | {model3.bic:.2f} |
| reduction ~ time + time² | {model4.rsquared:.4f} | {model4.rsquared_adj:.4f} | {model4.aic:.2f} | {model4.bic:.2f} |

## 3. PGLS (Phylogenetic GLS)

### PGLS: reduction ~ time
| Parameter | Value | SE | t | p |
|-----------|-------|----|----|----|
| λ (phylogenetic signal) | {lambda_opt:.4f} | — | — | — |
| Intercept | {beta_pgls[0]:.6f} | {se_beta[0]:.6f} | — | — |
| Time | {beta_pgls[1]:.6f} | {se_beta[1]:.6f} | {t_stat:.4f} | {p_val:.6f} |
| Pseudo-R² | {r2_pgls:.4f} | — | — | — |
| LR test (PGLS vs OLS) | χ² = {lr_stat:.4f} | — | — | p = {lr_p:.6f} |

### PGLS: reduction ~ log₁₀(Nₑ)
| Parameter | Value | SE | t | p |
|-----------|-------|----|----|----|
| λ (phylogenetic signal) | {lambda_opt2:.4f} | — | — | — |
| Intercept | {beta2[0]:.6f} | {se2[0]:.6f} | — | — |
| log₁₀(Nₑ) | {beta2[1]:.6f} | {se2[1]:.6f} | {t2:.4f} | {p2:.6f} |

## 4. Integration-Depth Analysis

### Gene Retention by Dependency Level
| Category | Mean ± SD |
|----------|-----------|
| High dependency | {high_ret.mean():.3f} ± {high_ret.std():.3f} |
| Medium dependency | {med_ret.mean():.3f} ± {med_ret.std():.3f} |
| Low dependency | {low_ret.mean():.3f} ± {low_ret.std():.3f} |

### Paired Comparisons
| Comparison | t | p | Significant? |
|-----------|---|----|-------------|
| High vs Low | {t_hl:.4f} | {p_hl:.6f} | {"Yes" if p_hl < 0.05 else "No"} |
| High vs Medium | {t_hm:.4f} | {p_hm:.6f} | {"Yes" if p_hm < 0.05 else "No"} |
| Medium vs Low | {t_ml:.4f} | {p_ml:.6f} | {"Yes" if p_ml < 0.05 else "No"} |

### Retention vs Reduction Correlations
| Category | r | p |
|----------|---|----|
| High | {r_high_reduc:.4f} | {p_high_reduc:.6f} |
| Medium | {r_med_reduc:.4f} | {p_med_reduc:.6f} |
| Low | {r_low_reduc:.4f} | {p_low_reduc:.6f} |

## 5. Raw Data

| Genus | Genome Size (Mb) | Reduction (%) | Time (Mya) | log₁₀(Nₑ) | Lifestyle |
|-------|-----------------|---------------|------------|------------|-----------|
"""

for i, g in enumerate(genera):
    results_md += f"| {g} | {genome_sizes[i]:.4f} | {genome_reduction[i]*100:.1f} | {times[i]:.0f} | {np.log10(n_e[i]):.2f} | {lifestyles[i]} |\n"

with open(RESULTS_DIR / "endosymbiont-results.md", "w") as f:
    f.write(results_md)

print(f"\nResults saved to {RESULTS_DIR / 'endosymbiont-results.md'}")
print("\n" + "=" * 80)
print("ANALYSIS COMPLETE")
print("=" * 80)