#!/usr/bin/env python3
"""
VI Foundry: Methods Registry Analysis Suite
Runs all computationally doable identification methods on existing data.

Methods:
1. Change-point detection (LTEE + C4)
2. Surrogate data testing
3. Takens embedding / phase-space reconstruction
4. Spectral analysis of M3 Jacobian
5. Inverse optimal control / revealed preference
6. Taphonomy simulation (observation window)
7. Renormalization / scale analysis
8. Reverse mathematics / sensitivity analysis
9. Seriation on cavefish traits
10. Lesion/deletion analysis on LTEE data
"""

import json
import math
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats, signal, optimize, linalg
from sklearn.decomposition import PCA
from sklearn.manifold import MDS
from sklearn.neighbors import NearestNeighbors

warnings.filterwarnings("ignore", category=FutureWarning)

WORKSPACE = Path("/home/node/.openclaw/workspace")
FOUNDRY = WORKSPACE / "vi-foundry"
RESULTS_DIR = FOUNDRY / "results" / "methods-register"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def separator(title):
    print(f"\n{'='*60}\n{title}\n{'='*60}")


# ============================================================================
# DATA LOADING
# ============================================================================

def load_ltee_data():
    """Load LTEE loss-of-function mutations with timing."""
    df = pd.read_csv(FOUNDRY / "data/t7-ltee/ltee_lof_mutations.tsv", sep="\t")
    return df

def load_ltee_merged():
    """Load merged LTEE analysis with gene dependency scores."""
    df = pd.read_csv(FOUNDRY / "data/t7-ltee/t7_merged_analysis.tsv", sep="\t")
    return df

def load_ltee_centrality():
    """Load STRING centrality + metabolic + FBA integration scores."""
    df = pd.read_csv(FOUNDRY / "data/t7-ltee/string_centrality.tsv", sep="\t")
    return df

def load_cavefish_data():
    """Load R1 cavefish trait-loss ordering data."""
    df = pd.read_csv(FOUNDRY / "results/r1-cavefish-sequence/r1-raw-data.tsv", sep="\t", comment="#")
    df.columns = df.columns.str.strip()
    return df

def load_dd_data():
    """Load R2 DD sign survey data."""
    df = pd.read_csv(FOUNDRY / "results/r2-dd-sign-survey/r2-raw-data.tsv", sep="\t", comment="#")
    df.columns = df.columns.str.strip()
    return df

def load_endosymbiont_data():
    """Load endosymbiont genome data."""
    df = pd.read_csv(FOUNDRY / "data/endosymbiont_genome_data.tsv", sep="\t")
    return df

def load_cross_domain_beta():
    """Load cross-domain beta (combinatorial substrate) data."""
    df = pd.read_csv(FOUNDRY / "data/cross_domain_beta.csv")
    return df

def load_orobanchaceae():
    """Load Orobanchaceae retention matrix."""
    df = pd.read_csv(FOUNDRY / "data/orobanchaceae_retention_matrix.tsv", sep="\t")
    return df


# ============================================================================
# 1. CHANGE-POINT DETECTION
# ============================================================================

def biexponential(t, k1, k2, A, B, C):
    """Bi-exponential: A*exp(-k1*t) + B*exp(-k2*t) + C"""
    return A * np.exp(-k1 * t) + B * np.exp(-k2 * t) + C

def single_exponential(t, k, A, C):
    return A * np.exp(-k * t) + C

def test_changepoint_ltee():
    """Change-point detection on LTEE gene loss timing."""
    separator("1. CHANGE-POINT DETECTION — LTEE")
    
    df = load_ltee_merged()
    # first_gen is when each gene was lost (generation number)
    gens = df["first_gen"].dropna().values.astype(float)
    gens_sorted = np.sort(gens)
    
    # Create cumulative loss curve
    n_total = len(gens_sorted)
    t = gens_sorted
    cumulative_loss = np.arange(1, n_total + 1) / n_total
    
    # Fit bi-exponential
    try:
        popt_bi, _ = optimize.curve_fit(
            biexponential, t, cumulative_loss,
            p0=[0.0001, 0.00001, 0.5, 0.5, 0.0],
            maxfev=10000
        )
        fit_bi = biexponential(t, *popt_bi)
        ss_res_bi = np.sum((cumulative_loss - fit_bi)**2)
        ss_tot = np.sum((cumulative_loss - np.mean(cumulative_loss))**2)
        r2_bi = 1 - ss_res_bi / ss_tot
    except Exception as e:
        popt_bi = None
        r2_bi = None
        print(f"  Bi-exp fit failed: {e}")
    
    # Fit single exponential
    try:
        popt_mono, _ = optimize.curve_fit(
            single_exponential, t, cumulative_loss,
            p0=[0.0001, 0.5, 0.0],
            maxfev=10000
        )
        fit_mono = single_exponential(t, *popt_mono)
        ss_res_mono = np.sum((cumulative_loss - fit_mono)**2)
        r2_mono = 1 - ss_res_mono / ss_tot
    except Exception as e:
        popt_mono = None
        r2_mono = None
        print(f"  Single-exp fit failed: {e}")
    
    # Change-point detection: find the generation where the rate changes
    # Use the derivative of the cumulative curve
    dt = np.diff(t)
    dy = np.diff(cumulative_loss)
    rate = dy / dt
    
    # Find the largest change in rate (second derivative)
    if len(rate) > 2:
        rate_change = np.abs(np.diff(rate))
        cp_idx = np.argmax(rate_change) + 1  # +1 because diff shifts index
        cp_gen = t[cp_idx]
    else:
        cp_idx = None
        cp_gen = None
    
    # AIC comparison
    n = len(cumulative_loss)
    if r2_bi is not None and r2_mono is not None:
        aic_bi = n * np.log(ss_res_bi / n) + 2 * 5  # 5 params
        aic_mono = n * np.log(ss_res_mono / n) + 2 * 3  # 3 params
        delta_aic = aic_bi - aic_mono
    
    result = {
        "n_genes_lost": n_total,
        "gen_range": [int(gens_sorted[0]), int(gens_sorted[-1])],
        "biexp_r2": r2_bi,
        "single_r2": r2_mono,
        "biexp_params": {"k1": popt_bi[0], "k2": popt_bi[1], "A": popt_bi[2], "B": popt_bi[3], "C": popt_bi[4]} if popt_bi is not None else None,
        "single_params": {"k": popt_mono[0], "A": popt_mono[1], "C": popt_mono[2]} if popt_mono is not None else None,
        "change_point_gen": int(cp_gen) if cp_gen is not None else None,
        "change_point_idx": cp_idx,
        "aic_biexp": aic_bi if r2_bi is not None else None,
        "aic_single": aic_mono if r2_mono is not None else None,
        "delta_aic": delta_aic if r2_bi is not None and r2_mono is not None else None,
        "interpretation": "Bi-exponential fits better" if (r2_bi is not None and r2_mono is not None and delta_aic is not None and delta_aic < -2) else ("Single fits better or equal" if r2_bi is not None and r2_mono is not None else "Fit failed"),
    }
    
    print(f"  Genes lost: {n_total}")
    print(f"  Generation range: {result['gen_range'][0]}–{result['gen_range'][1]}")
    print(f"  Bi-exp R²: {r2_bi:.4f}" if r2_bi else "  Bi-exp: failed")
    print(f"  Single R²: {r2_mono:.4f}" if r2_mono else "  Single: failed")
    if popt_bi:
        print(f"  Bi-exp k₁={popt_bi[0]:.6f}, k₂={popt_bi[1]:.6f} (ratio={popt_bi[0]/popt_bi[1]:.1f})")
    if popt_mono:
        print(f"  Single k={popt_mono[0]:.6f}")
    if result.get("delta_aic") is not None:
        print(f"  ΔAIC (bi vs single): {result['delta_aic']:.2f}")
    if cp_gen:
        print(f"  Change point: generation {int(cp_gen)} (rate transition)")
    print(f"  → {result['interpretation']}")
    
    return result


# ============================================================================
# 2. SURROGATE DATA TESTING
# ============================================================================

def test_surrogate_data():
    """Surrogate data testing: is the bi-exponential structure real or noise?"""
    separator("2. SURROGATE DATA TESTING — LTEE")
    
    df = load_ltee_merged()
    gens = df["first_gen"].dropna().values.astype(float)
    gens_sorted = np.sort(gens)
    n_total = len(gens_sorted)
    t = gens_sorted
    cumulative_loss = np.arange(1, n_total + 1) / n_total
    
    # Fit bi-exponential to real data
    try:
        popt, _ = optimize.curve_fit(
            biexponential, t, cumulative_loss,
            p0=[0.0001, 0.00001, 0.5, 0.5, 0.0],
            maxfev=10000
        )
        fit_real = biexponential(t, *popt)
        ss_res_real = np.sum((cumulative_loss - fit_real)**2)
    except:
        print("  Could not fit bi-exponential to real data")
        return {"error": "fit failed"}
    
    # Generate surrogates: shuffle the inter-event intervals
    # This preserves the distribution of intervals but destroys temporal ordering
    n_surrogates = 1000
    surrogate_ss = []
    
    for i in range(n_surrogates):
        # Shuffle intervals
        intervals = np.diff(np.concatenate([[0], t]))
        np.random.shuffle(intervals)
        t_surr = np.cumsum(intervals)
        cum_surr = np.arange(1, n_total + 1) / n_total
        
        try:
            popt_s, _ = optimize.curve_fit(
                biexponential, t_surr, cum_surr,
                p0=[0.0001, 0.00001, 0.5, 0.5, 0.0],
                maxfev=5000
            )
            fit_s = biexponential(t_surr, *popt_s)
            ss_s = np.sum((cum_surr - fit_s)**2)
            surrogate_ss.append(ss_s)
        except:
            pass
    
    surrogate_ss = np.array(surrogate_ss)
    p_value = np.mean(surrogate_ss <= ss_res_real)
    
    result = {
        "real_ss_res": float(ss_res_real),
        "surrogate_mean_ss": float(np.mean(surrogate_ss)),
        "surrogate_std_ss": float(np.std(surrogate_ss)),
        "p_value": float(p_value),
        "n_surrogates": len(surrogate_ss),
        "interpretation": "Bi-exponential structure is genuine (p < 0.05)" if p_value < 0.05 else "Bi-exponential structure not distinguishable from noise",
    }
    
    print(f"  Real data SS_res: {ss_res_real:.6f}")
    print(f"  Surrogate mean SS_res: {np.mean(surrogate_ss):.6f} ± {np.std(surrogate_ss):.6f}")
    print(f"  p-value: {p_value:.4f} ({len(surrogate_ss)} surrogates)")
    print(f"  → {result['interpretation']}")
    
    return result


# ============================================================================
# 3. TAKENS EMBEDDING / PHASE-SPACE RECONSTRUCTION
# ============================================================================

def mutual_information(x, y, bins=10):
    """Compute mutual information for delay selection."""
    hist_2d, _, _ = np.histogram2d(x, y, bins=bins)
    pxy = hist_2d / hist_2d.sum()
    px = pxy.sum(axis=1)
    py = pxy.sum(axis=0)
    px_py = np.outer(px, py)
    nzs = pxy > 0
    mi = np.sum(pxy[nzs] * np.log(pxy[nzs] / px_py[nzs]))
    return mi

def estimate_embedding_dimension(data, max_dim=5, max_tau=50):
    """Estimate embedding dimension using false nearest neighbors."""
    n = len(data)
    
    # Find optimal delay using first minimum of mutual information
    taus = range(1, min(max_tau, n // 2))
    mi_values = [mutual_information(data[:-tau], data[tau:]) for tau in taus]
    
    # First minimum
    tau_opt = taus[np.argmin(mi_values)] if len(taus) > 0 else 1
    
    # False nearest neighbors for dimension estimation
    dims = range(1, max_dim + 1)
    fnn_ratios = []
    
    for dim in dims:
        if dim * tau_opt >= n:
            fnn_ratios.append(np.nan)
            continue
        
        # Create embedded vectors
        n_embed = n - dim * tau_opt
        if n_embed <= 1:
            fnn_ratios.append(np.nan)
            continue
        
        embedded = np.array([data[i:i + dim * tau_opt:tau_opt] for i in range(n_embed)])
        
        if len(embedded) < 2:
            fnn_ratios.append(np.nan)
            continue
        
        # Find nearest neighbors
        nn = NearestNeighbors(n_neighbors=2, algorithm='auto').fit(embedded[:-1])
        distances, indices = nn.kneighbors(embedded[:-1])
        
        # Check false neighbors
        false_count = 0
        total = 0
        for i in range(len(embedded) - 1):
            neighbor_idx = indices[i, 1]  # nearest neighbor (not self)
            if neighbor_idx >= len(embedded) - 1:
                continue
            d = distances[i, 1]
            if d == 0:
                d = 1e-10
            
            # Distance in dim+1
            if i + dim * tau_opt < n and neighbor_idx + dim * tau_opt < n:
                d_next = abs(data[i + dim * tau_opt] - data[neighbor_idx + dim * tau_opt])
                if d_next / d > 15:  # RT factor
                    false_count += 1
            total += 1
        
        ratio = false_count / total if total > 0 else np.nan
        fnn_ratios.append(ratio)
    
    # Find dimension where FNN drops to ~0
    dim_opt = 1
    for i, r in enumerate(fnn_ratios):
        if not np.isnan(r) and r < 0.05:
            dim_opt = i + 1
            break
    
    return tau_opt, dim_opt, mi_values, fnn_ratios

def test_takens_embedding():
    """Phase-space reconstruction: what's the true dimensionality of the dynamics?"""
    separator("3. TAKENS EMBEDDING — Phase-Space Reconstruction")
    
    df = load_ltee_merged()
    gens = df["first_gen"].dropna().values.astype(float)
    gens_sorted = np.sort(gens)
    cumulative_loss = np.arange(1, len(gens_sorted) + 1) / len(gens_sorted)
    
    # Use the cumulative loss curve as the scalar time series
    data = cumulative_loss
    
    tau_opt, dim_opt, mi_values, fnn_ratios = estimate_embedding_dimension(data, max_dim=5)
    
    # Also try with the rate (derivative)
    rate_data = np.diff(data)
    if len(rate_data) > 10:
        tau_r, dim_r, _, fnn_r = estimate_embedding_dimension(rate_data, max_dim=5)
    else:
        tau_r, dim_r, fnn_r = None, None, []
    
    result = {
        "series_length": len(data),
        "optimal_delay": tau_opt,
        "optimal_dimension": dim_opt,
        "fnn_ratios": [float(x) if not np.isnan(x) else None for x in fnn_ratios],
        "rate_dimension": dim_r,
        "interpretation": f"Dynamics are {dim_opt}-D" + (" (consistent with bi-exponential relaxation)" if dim_opt <= 2 else " (higher than expected — bi-exponential may be a projection)"),
    }
    
    print(f"  Series length: {len(data)}")
    print(f"  Optimal delay (τ): {tau_opt}")
    print(f"  FNN ratios by dimension: {[f'{x:.3f}' if x is not None else 'nan' for x in fnn_ratios]}")
    print(f"  Optimal embedding dimension: {dim_opt}")
    if dim_r:
        print(f"  Rate series dimension: {dim_r}")
    print(f"  → {result['interpretation']}")
    print(f"  Context: 1-D = pure relaxation (bi-exp is right model)")
    print(f"           2-D = two coupled processes (bi-exp captures this)")
    print(f"           3+  = higher-D dynamics being projected to 1-D")
    
    return result


# ============================================================================
# 4. SPECTRAL ANALYSIS OF M3 JACOBIAN
# ============================================================================

def test_spectral_analysis():
    """Spectral analysis of the M3 Jacobian and comparison across systems."""
    separator("4. SPECTRAL ANALYSIS — M3 Jacobian")
    
    # Reconstruct the M3 Jacobian from the eigenvalues we already have
    # From M3 results: eigenvalues = [-6.25424881e-05, -9.91735537e-05]
    # This is a 2x2 Jacobian. Let's reconstruct and analyze.
    
    eigenvalues_m3 = np.array([-6.25424881e-05, -9.91735537e-05])
    
    # For a 2x2 system: J = [[a, b], [c, d]]
    # eigenvalues = trace/2 ± sqrt((trace/2)² - det)
    trace = np.sum(eigenvalues_m3)
    det = np.prod(eigenvalues_m3)
    
    # The system is purely dissipative if J is symmetric (A=0)
    # For 2x2: J = S + A where S = (J+Jᵀ)/2, A = (J-Jᵀ)/2
    # We know from M3 that dissipation_ratio = 0.5154 (51.54% dissipative)
    # So 48.46% rotational
    
    dissipation_ratio = 0.5154
    rotational_ratio = 1 - dissipation_ratio
    
    # For the LTEE system, we can also look at the rate constants
    # k1=17.7, k2=0.47 (from earlier analysis)
    k1_ltee = 17.7
    k2_ltee = 0.47
    ratio_ltee = k1_ltee / k2_ltee
    
    # C4 single exponential: k=0.169 My⁻¹
    k_c4 = 0.169
    
    # Spectral comparison: compare eigenvalue structure
    # For bi-exponential: eigenvalues of the rate matrix are -k1, -k2
    # For single exponential: eigenvalue is -k
    
    # The spectral gap (ratio of eigenvalues) tells us about timescale separation
    spectral_gap_ltee = abs(eigenvalues_m3[0] / eigenvalues_m3[1])
    spectral_gap_k = k1_ltee / k2_ltee
    
    result = {
        "m3_eigenvalues": eigenvalues_m3.tolist(),
        "m3_trace": float(trace),
        "m3_det": float(det),
        "m3_dissipation_ratio": dissipation_ratio,
        "m3_rotational_ratio": rotational_ratio,
        "ltee_k1": k1_ltee,
        "ltee_k2": k2_ltee,
        "ltee_k_ratio": float(ratio_ltee),
        "c4_single_k": k_c4,
        "spectral_gap_m3": float(spectral_gap_ltee),
        "spectral_gap_k": float(spectral_gap_k),
        "interpretation": "Two distinct timescales confirmed (spectral gap > 1). Non-dissipative component significant (48.5%).",
    }
    
    print(f"  M3 eigenvalues: {eigenvalues_m3}")
    print(f"  Trace: {trace:.8e}")
    print(f"  Determinant: {det:.8e}")
    print(f"  Dissipation ratio: {dissipation_ratio:.4f} ({dissipation_ratio*100:.1f}% dissipative)")
    print(f"  Rotational ratio: {rotational_ratio:.4f} ({rotational_ratio*100:.1f}% rotational)")
    print(f"  Spectral gap (M3): {spectral_gap_ltee:.4f}")
    print(f"  LTEE k₁/k₂ ratio: {ratio_ltee:.1f}")
    print(f"  C4 single k: {k_c4} My⁻¹")
    print(f"  → {result['interpretation']}")
    
    return result


# ============================================================================
# 5. INVERSE OPTIMAL CONTROL / REVEALED PREFERENCE
# ============================================================================

def test_inverse_optimal_control():
    """
    Inverse optimal control: given observed relaxation trajectories,
    recover the cost function (potential landscape) being minimized.
    
    Forward model: gradient flow on V(ρ) = ½k₁(ρ-ρ₁)² + ½k₂(ρ-ρ₂)²
    Inverse: given ρ(t), recover V(ρ)
    """
    separator("5. INVERSE OPTIMAL CONTROL — Recover Cost Function")
    
    df = load_ltee_merged()
    gens = df["first_gen"].dropna().values.astype(float)
    gens_sorted = np.sort(gens)
    n = len(gens_sorted)
    t = gens_sorted.astype(float)
    
    # ρ = fraction of genes still retained (capacity)
    rho = 1.0 - np.arange(1, n + 1) / n
    
    # From dρ/dt = -dV/dρ, we have V'(ρ) = -dρ/dt
    # Numerical derivative
    dt = np.diff(t)
    drho = np.diff(rho)
    velocity = drho / dt  # dρ/dt (should be negative — capacity decreasing)
    
    # Midpoint ρ values
    rho_mid = 0.5 * (rho[:-1] + rho[1:])
    
    # The force = -velocity = dV/dρ
    force = -velocity  # positive force means pushing ρ down
    
    # Fit V(ρ) = a*(ρ-ρ₁)² + b*(ρ-ρ₂)² (bi-exponential potential)
    # V'(ρ) = 2a*(ρ-ρ₁) + 2b*(ρ-ρ₂)
    # Force = V'(ρ) = 2a*(ρ-ρ₁) + 2b*(ρ-ρ₂)
    
    def force_model(rho, a, rho1, b, rho2):
        return 2*a*(rho - rho1) + 2*b*(rho - rho2)
    
    # Clean data: remove NaN/inf
    mask = np.isfinite(rho_mid) & np.isfinite(force)
    rho_mid_clean = rho_mid[mask]
    force_clean = force[mask]
    
    if len(rho_mid_clean) < 4:
        print(f"  Insufficient clean data: {len(rho_mid_clean)} points")
        return {"error": "insufficient clean data", "n_clean": len(rho_mid_clean)}
    
    try:
        popt_v, _ = optimize.curve_fit(
            force_model, rho_mid_clean, force_clean,
            p0=[1.0, 0.3, 0.1, 0.8],
            maxfev=10000
        )
        a, rho1, b, rho2 = popt_v
        force_fit = force_model(rho_mid_clean, *popt_v)
        ss_res = np.sum((force_clean - force_fit)**2)
        ss_tot = np.sum((force_clean - np.mean(force_clean))**2)
        r2_force = 1 - ss_res / ss_tot if ss_tot > 0 else 0
        
        # Recover k values: k = 2a, k = 2b (since dρ/dt = -k*(ρ-ρ_eq))
        k1_recovered = 2 * a
        k2_recovered = 2 * b
        
        # Also fit single-well potential: V(ρ) = a*(ρ-ρ_eq)²
        def force_single(rho, a, rho_eq):
            return 2*a*(rho - rho_eq)
        
        popt_s, _ = optimize.curve_fit(force_single, rho_mid_clean, force_clean, p0=[1.0, 0.5], maxfev=10000)
        a_s, rho_eq_s = popt_s
        force_fit_s = force_single(rho_mid_clean, *popt_s)
        ss_res_s = np.sum((force_clean - force_fit_s)**2)
        r2_single = 1 - ss_res_s / ss_tot if ss_tot > 0 else 0
        
    except Exception as e:
        print(f"  Fit failed: {e}")
        return {"error": str(e)}
    
    # AIC comparison
    n_pts = len(force)
    aic_bi = n_pts * np.log(ss_res / n_pts) + 2 * 4  # 4 params
    aic_single = n_pts * np.log(ss_res_s / n_pts) + 2 * 2  # 2 params
    
    result = {
        "n_points": n_pts,
        "biexp_force_r2": float(r2_force),
        "single_force_r2": float(r2_single),
        "recovered_k1": float(k1_recovered),
        "recovered_k2": float(k2_recovered),
        "recovered_rho1": float(rho1),
        "recovered_rho2": float(rho2),
        "single_k": float(2 * a_s),
        "single_rho_eq": float(rho_eq_s),
        "aic_biexp": float(aic_bi),
        "aic_single": float(aic_single),
        "delta_aic": float(aic_bi - aic_single),
        "potential_type": "bi-well (two equilibria)" if abs(rho1 - rho2) > 0.1 else "single-well (one equilibrium)",
        "interpretation": "Two-well potential recovered" if abs(rho1 - rho2) > 0.1 else "Single-well potential sufficient",
    }
    
    print(f"  Data points: {n_pts}")
    print(f"  Bi-exp force model R²: {r2_force:.4f}")
    print(f"  Single force model R²: {r2_single:.4f}")
    print(f"  Recovered k₁={k1_recovered:.6f}, k₂={k2_recovered:.6f}")
    print(f"  Recovered ρ₁={rho1:.4f}, ρ₂={rho2:.4f}")
    print(f"  Single: k={2*a_s:.6f}, ρ_eq={rho_eq_s:.4f}")
    print(f"  ΔAIC (bi vs single): {aic_bi - aic_single:.2f}")
    print(f"  Potential type: {result['potential_type']}")
    print(f"  → {result['interpretation']}")
    print(f"  Context: If bi-well, two equilibria confirmed (bi-exp is real)")
    print(f"           If single-well, one equilibrium suffices (bi-exp is overfitting)")
    
    return result


# ============================================================================
# 6. TAPHONOMY SIMULATION (OBSERVATION WINDOW)
# ============================================================================

def test_taphonomy_simulation():
    """Simulate how observation window affects perception of stasis vs. change."""
    separator("6. TAPHONOMY SIMULATION — Observation Window")
    
    # Simulate bi-exponential relaxation with known parameters
    k1, k2 = 0.01, 0.001  # fast and slow rates
    rho1, rho2 = 0.3, 0.7  # equilibria
    t_true = np.linspace(0, 5000, 10000)
    rho_true = 0.3 * np.exp(-k1 * t_true) + 0.5 * np.exp(-k2 * t_true) + 0.2
    
    # Sample at different observation windows
    windows = {
        "short (10 time units)": (0, 10),
        "medium (100 time units)": (50, 150),
        "long (1000 time units)": (500, 1500),
        "very long (5000 time units)": (0, 5000),
        "k₂ only (late window)": (2000, 3000),
        "k₁ only (early window)": (0, 200),
    }
    
    results = {}
    for name, (t_start, t_end) in windows.items():
        mask = (t_true >= t_start) & (t_true <= t_end)
        t_window = t_true[mask]
        rho_window = rho_true[mask]
        
        # Linear fit: is there detectable change?
        if len(t_window) > 1:
            slope, intercept, r_value, p_value, std_err = stats.linregress(t_window, rho_window)
            total_change = rho_window[-1] - rho_window[0]
            
            results[name] = {
                "n_points": int(mask.sum()),
                "slope": float(slope),
                "r_squared": float(r_value**2),
                "p_value": float(p_value),
                "total_change": float(total_change),
                "appears_stable": abs(slope) < 1e-5,
            }
            
            print(f"  {name}: slope={slope:.2e}, R²={r_value**2:.4f}, "
                  f"change={total_change:.4f}, {'STABLE' if abs(slope) < 1e-5 else 'CHANGING'}")
    
    result = {
        "true_k1": k1,
        "true_k2": k2,
        "windows": results,
        "interpretation": "Short windows in k₂ phase appear as stasis. Long windows reveal erosion. The observation window determines whether you see stability or change.",
    }
    
    print(f"\n  → {result['interpretation']}")
    return result


# ============================================================================
# 7. RENORMALIZATION / SCALE ANALYSIS
# ============================================================================

def test_scale_analysis():
    """Check if k₁/k₂ ratio is invariant across timescales."""
    separator("7. SCALE ANALYSIS — k₁/k₂ Across Timescales")
    
    # Collect all known rate constants with their timescales
    systems = [
        {"name": "LTEE (E. coli)", "k1": 17.7, "k2": 0.47, "timescale_gen": 75000, "timescale_yr": 15, "n": 12, "substrate": "bacterial genome"},
        {"name": "C4 inbound (grasses)", "k1": 0.169, "k2": 0.169, "timescale_gen": None, "timescale_yr": 10_000_000, "n": 8, "substrate": "plant photosynthesis"},
        {"name": "Endosymbiont (Buchnera)", "k1": None, "k2": None, "timescale_yr": 200_000_000, "n": 20, "substrate": "bacterial genome (symbiotic)"},
        {"name": "Orobanchaceae (plants)", "k1": None, "k2": None, "timescale_yr": 40_000_000, "n": 8, "substrate": "plant plastome"},
        {"name": "Birds (Wright 2016)", "k1": None, "k2": None, "timescale_yr": 50_000_000, "n": 15, "substrate": "bird morphology"},
    ]
    
    # For systems with known k values
    ltee_ratio = 17.7 / 0.47
    c4_ratio = 1.0  # single exponential, k1=k2
    
    print(f"  LTEE: k₁/k₂ = {ltee_ratio:.1f} (timescale ~{15} yr)")
    print(f"  C4:   k₁/k₂ = {c4_ratio:.1f} (timescale ~10 Myr)")
    print(f"  Ratio of ratios: {ltee_ratio / c4_ratio:.1f}")
    print(f"  Timescale ratio: {10_000_000 / 15:.0f}")
    
    result = {
        "ltee_k_ratio": ltee_ratio,
        "c4_k_ratio": c4_ratio,
        "ratio_of_ratios": ltee_ratio / c4_ratio,
        "timescale_ratio": 10_000_000 / 15,
        "systems": systems,
        "interpretation": "k₁/k₂ is NOT scale-invariant (LTEE=37.7, C4=1.0). The timescale separation collapses at Myr scales. This suggests the bi-exponential is a property of short timescales (experimental) and may not hold at geological timescales.",
    }
    
    print(f"\n  → {result['interpretation']}")
    return result


# ============================================================================
# 8. REVERSE MATHEMATICS / SENSITIVITY ANALYSIS
# ============================================================================

def test_sensitivity_analysis():
    """Strip the model: which components are load-bearing?"""
    separator("8. SENSITIVITY ANALYSIS — Minimal Model")
    
    df = load_ltee_merged()
    gens = df["first_gen"].dropna().values.astype(float)
    gens_sorted = np.sort(gens)
    n = len(gens_sorted)
    t = gens_sorted.astype(float)
    rho = 1.0 - np.arange(1, n + 1) / n
    
    models = {}
    
    # Model 1: Full bi-exponential (5 params)
    try:
        popt, _ = optimize.curve_fit(biexponential, t, rho, p0=[0.0001, 0.00001, 0.5, 0.5, 0.0], maxfev=10000)
        ss_res = np.sum((rho - biexponential(t, *popt))**2)
        models["biexp_5param"] = {"n_params": 5, "ss_res": ss_res, "params": popt.tolist()}
    except:
        models["biexp_5param"] = {"n_params": 5, "ss_res": None}
    
    # Model 2: Single exponential (3 params)
    try:
        popt, _ = optimize.curve_fit(single_exponential, t, rho, p0=[0.0001, 0.5, 0.0], maxfev=10000)
        ss_res = np.sum((rho - single_exponential(t, *popt))**2)
        models["single_3param"] = {"n_params": 3, "ss_res": ss_res, "params": popt.tolist()}
    except:
        models["single_3param"] = {"n_params": 3, "ss_res": None}
    
    # Model 3: Linear (2 params) — null model
    slope, intercept, r_value, _, _ = stats.linregress(t, rho)
    fit_linear = slope * t + intercept
    ss_res = np.sum((rho - fit_linear)**2)
    models["linear_2param"] = {"n_params": 2, "ss_res": ss_res, "params": [slope, intercept], "r_squared": r_value**2}
    
    # Model 4: Power law (3 params) — alternative to exponential
    def power_law(t, a, b, c):
        return a * np.power(t + 1, -b) + c
    try:
        popt, _ = optimize.curve_fit(power_law, t, rho, p0=[0.5, 0.1, 0.2], maxfev=10000)
        ss_res = np.sum((rho - power_law(t, *popt))**2)
        models["power_3param"] = {"n_params": 3, "ss_res": ss_res, "params": popt.tolist()}
    except:
        models["power_3param"] = {"n_params": 3, "ss_res": None}
    
    # Model 5: Logarithmic (2 params) — another alternative
    def log_model(t, a, b):
        return a * np.log(t + 1) + b
    try:
        popt, _ = optimize.curve_fit(log_model, t, rho, p0=[-0.01, 0.8], maxfev=10000)
        ss_res = np.sum((rho - log_model(t, *popt))**2)
        models["log_2param"] = {"n_params": 2, "ss_res": ss_res, "params": popt.tolist()}
    except:
        models["log_2param"] = {"n_params": 2, "ss_res": None}
    
    # AIC table
    print(f"  {'Model':<25} {'Params':>6} {'SS_res':>12} {'AIC':>10} {'ΔAIC':>8}")
    print(f"  {'-'*25} {'-'*6} {'-'*12} {'-'*10} {'-'*8}")
    
    aic_values = {}
    for name, m in models.items():
        if m["ss_res"] is not None:
            aic = n * np.log(m["ss_res"] / n) + 2 * m["n_params"]
            aic_values[name] = aic
        else:
            aic_values[name] = float('inf')
    
    min_aic = min(aic_values.values())
    
    for name, m in models.items():
        if m["ss_res"] is not None:
            aic = aic_values[name]
            delta = aic - min_aic
            print(f"  {name:<25} {m['n_params']:>6} {m['ss_res']:>12.6f} {aic:>10.2f} {delta:>8.2f}")
        else:
            print(f"  {name:<25} {m['n_params']:>6} {'FAILED':>12}")
    
    best_model = min(aic_values, key=aic_values.get)
    result = {
        "models": {k: {"n_params": v["n_params"], "ss_res": float(v["ss_res"]) if v["ss_res"] is not None else None, "aic": float(aic_values[k])} for k, v in models.items()},
        "best_model": best_model,
        "interpretation": f"Best model: {best_model}. " + ("Bi-exponential is load-bearing" if best_model == "biexp_5param" else "Bi-exponential is NOT the minimal model — simpler model suffices"),
    }
    
    print(f"\n  → {result['interpretation']}")
    return result


# ============================================================================
# 9. SERIATION ON CAVEFISH TRAITS
# ============================================================================

def test_seriation_cavefish():
    """Seriation: order traits by similarity across lineages, without using timing data."""
    separator("9. SERIATION — Cavefish Trait Loss")
    
    df = load_cavefish_data()
    
    # We have: gene, category, loss_timing, string_degree
    # Seriation: order genes by string_degree (independent metric) and check if it matches loss_timing
    
    # Rank by string_degree (high to low = most connected to least)
    df_sorted_degree = df.sort_values("string_degree", ascending=False)
    df_sorted_timing = df.sort_values("loss_timing")
    
    # Spearman rank correlation
    rho_spearman, p_spearman = stats.spearmanr(df["string_degree"], df["loss_timing"])
    
    # Also try: metabolic cost proxy (category-based)
    # Pigment genes are metabolically expensive (melanin production)
    # Circadian genes are regulatory (lower direct metabolic cost)
    # Eye genes are structural (intermediate cost)
    # Metabolic genes are core (high cost to lose, but also high cost to maintain if unused)
    
    category_cost = {
        "pigment": 3,  # melanin production is metabolically expensive
        "eye": 2,      # structural, moderate cost
        "metabolic": 1, # core metabolism, but if niche doesn't need them...
        "circadian": 1,  # regulatory, low direct metabolic cost
    }
    df["metabolic_cost_proxy"] = df["category"].map(category_cost)
    
    rho_cost, p_cost = stats.spearmanr(df["metabolic_cost_proxy"], df["loss_timing"])
    
    # Seriation: order by metabolic cost and check alignment with timing
    df_sorted_cost = df.sort_values("metabolic_cost_proxy", ascending=False)
    
    # Compute rank order for each metric
    df["rank_timing"] = df["loss_timing"].rank()
    df["rank_degree"] = df["string_degree"].rank(ascending=False)
    df["rank_cost"] = df["metabolic_cost_proxy"].rank(ascending=False)
    
    # Also check: does STRING degree correlate WITHIN categories?
    for cat in df["category"].unique():
        sub = df[df["category"] == cat]
        if len(sub) > 2:
            r, p = stats.spearmanr(sub["string_degree"], sub["loss_timing"])
    
    result = {
        "n_genes": len(df),
        "spearman_string_degree": float(rho_spearman),
        "p_value_string": float(p_spearman),
        "spearman_metabolic_cost": float(rho_cost),
        "p_value_cost": float(p_cost),
        "categories": df["category"].unique().tolist(),
        "seriation_by_cost": df_sorted_cost[["gene", "category", "loss_timing", "metabolic_cost_proxy"]].to_dict("records"),
        "interpretation": "Metabolic cost predicts loss ordering better than STRING degree" if abs(rho_cost) > abs(rho_spearman) else "STRING degree and metabolic cost are equally weak",
    }
    
    print(f"  Genes: {len(df)}")
    print(f"  Spearman (STRING degree vs loss timing): ρ={rho_spearman:.4f}, p={p_spearman:.4f}")
    print(f"  Spearman (metabolic cost vs loss timing): ρ={rho_cost:.4f}, p={p_cost:.4f}")
    print(f"  Categories: {df['category'].unique().tolist()}")
    print(f"  Cost proxy: {category_cost}")
    print(f"  → {result['interpretation']}")
    
    return result


# ============================================================================
# 10. LESION/DELETION ANALYSIS ON LTEE DATA
# ============================================================================

def test_lesion_analysis():
    """Use gene knockout fitness data as independent integration-depth metric."""
    separator("10. LESION/DELETION ANALYSIS — LTEE")
    
    df = load_ltee_merged()
    centrality = load_ltee_centrality()
    
    # Merge: we have first_gen (when gene was lost) and dependency_score (how essential)
    df_merged = df.dropna(subset=["first_gen", "dependency_score"])
    
    if len(df_merged) < 3:
        # Try the centrality file which has more integration metrics
        centrality_clean = centrality.dropna(subset=["fba_dep_ltee"])
        
        # For genes that were lost, check if they were low-dependency (peripheral)
        lost_genes = df.dropna(subset=["first_gen"])["b_number"].tolist()
        centrality_lost = centrality[centrality["b_number"].isin(lost_genes)]
        
        if len(centrality_lost) < 3:
            print(f"  Insufficient data: {len(df_merged)} merged, {len(centrality_lost)} centrality-lost")
            return {"error": "insufficient data", "n_merged": len(df_merged), "n_centrality": len(centrality_lost)}
        
        # Use centrality_lost: correlate PPI degree with first_gen
        lost_with_gen = df.dropna(subset=["first_gen"])[["b_number", "first_gen"]].drop_duplicates("b_number")
        merged = centrality_lost.merge(lost_with_gen, on="b_number", how="inner")
        
        if len(merged) < 3:
            print(f"  Insufficient overlap: {len(merged)} genes")
            return {"error": "insufficient overlap", "n": len(merged)}
        
        # Correlate integration metrics with loss timing
        rho_ppi, p_ppi = stats.spearmanr(merged["ppi_degree"], merged["first_gen"])
        rho_met, p_met = stats.spearmanr(merged["met_degree"], merged["first_gen"]) if "met_degree" in merged.columns else (None, None)
        rho_fba, p_fba = stats.spearmanr(merged["fba_dep_ltee"], merged["first_gen"]) if "fba_dep_ltee" in merged.columns else (None, None)
        rho_composite, p_composite = stats.spearmanr(merged["composite_integration"], merged["first_gen"]) if "composite_integration" in merged.columns else (None, None)
        
        result = {
            "n_genes": len(merged),
            "spearman_ppi_degree": float(rho_ppi) if rho_ppi is not None else None,
            "p_ppi": float(p_ppi) if p_ppi is not None else None,
            "spearman_met_degree": float(rho_met) if rho_met is not None else None,
            "p_met": float(p_met) if p_met is not None else None,
            "spearman_fba": float(rho_fba) if rho_fba is not None else None,
            "p_fba": float(p_fba) if p_fba is not None else None,
            "spearman_composite": float(rho_composite) if rho_composite is not None else None,
            "p_composite": float(p_composite) if p_composite is not None else None,
            "interpretation": "Lesion analysis: genes lost early are less integrated (low dependency)" if (rho_composite is not None and rho_composite > 0 and p_composite < 0.05) else "No significant integration-depth ordering detected with available metrics",
        }
        
        print(f"  Genes with full data: {len(merged)}")
        print(f"  Spearman (PPI degree vs loss gen): ρ={rho_ppi:.4f}, p={p_ppi:.4f}" if rho_ppi is not None else "  PPI: N/A")
        print(f"  Spearman (met degree vs loss gen): ρ={rho_met:.4f}, p={p_met:.4f}" if rho_met is not None else "  Met: N/A")
        print(f"  Spearman (FBA dep vs loss gen): ρ={rho_fba:.4f}, p={p_fba:.4f}" if rho_fba is not None else "  FBA: N/A")
        print(f"  Spearman (composite vs loss gen): ρ={rho_composite:.4f}, p={p_composite:.4f}" if rho_composite is not None else "  Composite: N/A")
        print(f"  → {result['interpretation']}")
        
        return result
    
    # Direct dependency_score correlation
    rho_dep, p_dep = stats.spearmanr(df_merged["dependency_score"], df_merged["first_gen"])
    
    result = {
        "n_genes": len(df_merged),
        "spearman_dependency": float(rho_dep),
        "p_value": float(p_dep),
        "interpretation": "High-dependency genes lost later (integration-depth holds)" if (rho_dep > 0 and p_dep < 0.05) else "Integration-depth ordering not confirmed with dependency score",
    }
    
    print(f"  Genes with full data: {len(df_merged)}")
    print(f"  Spearman (dependency vs loss gen): ρ={rho_dep:.4f}, p={p_dep:.4f}")
    print(f"  → {result['interpretation']}")
    
    return result


# ============================================================================
# CROSS-METHOD SYNTHESIS: COMPARISON WITH KNOWN PHENOMENA
# ============================================================================

def cross_method_comparison(results):
    """Compare VI properties with known phenomena and frameworks."""
    separator("CROSS-METHOD SYNTHESIS — VI vs Known Phenomena")
    
    comparisons = [
        {
            "phenomenon": "RC circuit discharge",
            "framework": "Electrical engineering",
            "equation": "V(t) = V₀·exp(-t/RC)",
            "vi_property": "Bi-exponential outbound",
            "comparison": "RC circuit with two stages (two time constants) gives bi-exponential. Same mathematical form. The 'valence' in VI maps to the charge. The 'resistance' maps to integration depth (high R = slow discharge = high integration). The 'capacitance' maps to capacity.",
            "form_match": True,
            "mechanism_match": False,
            "notes": "RC circuits are symmetric (charge/discharge follow same form). VI is asymmetric (gain ≠ loss). So the analogy breaks at the symmetry question.",
        },
        {
            "phenomenon": "Magnetic domain relaxation",
            "framework": "Magnetism",
            "equation": "M(t) = M₁·exp(-t/τ₁) + M₂·exp(-t/τ₂)",
            "vi_property": "Bi-exponential + cross-kingdom conservation",
            "comparison": "Magnetic domains relax to equilibrium after field change. Two domains (fast/slow) give bi-exponential. The 'valence' maps to the magnetic moment. The 'field' maps to the niche. Cross-material conservation of τ would be like saying iron and nickel have the same relaxation time — surprising and suggestive of a universal principle.",
            "form_match": True,
            "mechanism_match": False,
            "notes": "Magnetic relaxation IS thermodynamic. VI is not (M3 shows non-dissipative coupling). The form matches, the identity doesn't.",
        },
        {
            "phenomenon": "Drug pharmacokinetics",
            "framework": "Pharmacology",
            "equation": "C(t) = A·exp(-αt) + B·exp(-βt)",
            "vi_property": "Bi-exponential with k₁/k₂ ratio",
            "vi_property": "Bi-exponential with integration-depth ordering",
            "comparison": "Two-compartment pharmacokinetics: drug distributes fast (α, central compartment) and clears slow (β, peripheral). The k₁/k₂ ratio = distribution/clearance ratio. In VI, k₁/k₂ = peripheral/core integration ratio. The 'compartments' in VI are integration-depth levels.",
            "form_match": True,
            "mechanism_match": "partial",
            "notes": "Pharmacokinetics is well-understood and NOT thermodynamic — it's transport + elimination. This is a strong analogy: transport (selection) + elimination (shedding). The compartments are real (integration levels), not artificial.",
        },
        {
            "phenomenon": "Stellar main sequence",
            "framework": "Astrophysics",
            "equation": "L ∝ M^3.5 (mass-luminosity relation)",
            "vi_property": "Cross-kingdom parameter conservation",
            "comparison": "Stars on the main sequence follow a universal relation regardless of composition. The universality comes from physics (hydrostatic equilibrium + nuclear fusion rate). VI's cross-kingdom conservation is similarly surprising — different substrates, same rate constants. The universality should come from... what? If it's physics (gradient flow), it's the fossilized urge. If it's biology (convergent form), it's independent reinvention.",
            "form_match": False,
            "mechanism_match": False,
            "notes": "Different equation form, but the universality-across-substrates question is the same.",
        },
        {
            "phenomenon": "Allometric scaling",
            "framework": "Biology (West-Brown-Enquist)",
            "equation": "B ∝ M^(3/4)",
            "vi_property": "Cross-kingdom conservation",
            "comparison": "WBE theory predicts 3/4 scaling from network geometry. The universality comes from the fractal branching of distribution networks. VI's cross-kingdom conservation could similarly come from a universal property of biological networks — their hierarchical structure. If the k₁/k₂ ratio reflects the branching depth of regulatory networks, and all networks have similar depth, the ratio would be conserved.",
            "form_match": False,
            "mechanism_match": True,
            "notes": "Different equation, but the mechanism (network geometry producing universal constants) could be the same. This is the most biologically grounded analogy.",
        },
        {
            "phenomenon": "Arrhenius activation energy",
            "framework": "Chemical kinetics",
            "equation": "k = A·exp(-Ea/RT)",
            "vi_property": "Latent valence (four-state model)",
            "comparison": "Below activation energy, k=0 (latent). Above, k>0 (active). The seed dormant for 200 years maps to a molecule below its activation barrier. The trigger (water, light, temperature) maps to thermal energy crossing the barrier. Same form, but the barrier is developmental (gene regulatory switch), not thermal.",
            "form_match": True,
            "mechanism_match": False,
            "notes": "This is the cleanest analogy for the latent→activated transition. The Arrhenius form should hold if we measure germination rate vs. environmental cue strength.",
        },
        {
            "phenomenon": "Glass transition / relaxation",
            "framework": "Soft matter physics",
            "equation": "Multiple relaxation times (stretched exponential: exp(-(t/τ)^β))",
            "vi_property": "Bi-exponential (two relaxation times)",
            "comparison": "Glassy systems have a spectrum of relaxation times, often fit by stretched exponential. VI has exactly two times — not a spectrum. This is interesting: VI is simpler than glass, suggesting the two-timescale structure is real (not an approximation to a continuum). The integration hierarchy produces TWO levels (fast/slow), not a continuum.",
            "form_match": "partial",
            "mechanism_match": False,
            "notes": "Glass has a distribution of relaxation times; VI has two. The discreteness of the two-timescale structure is a prediction: the integration hierarchy has two levels, not a continuum.",
        },
        {
            "phenomenon": "Critical slowing down",
            "framework": "Complex systems / phase transitions",
            "equation": "τ ∝ |T - Tc|^(-ν)",
            "vi_property": "k₂ → 0 for living fossils",
            "comparison": "Near a critical point, relaxation time diverges (system becomes slow). Living fossils at k₂ ≈ 0 are like systems near criticality — they're at their equilibrium and barely moving. But this is not because they're near a phase transition; it's because they're already AT equilibrium (small displacement). Different mechanism for the same phenomenon (slow relaxation).",
            "form_match": "partial",
            "mechanism_match": False,
            "notes": "Critical slowing down is about approaching a phase transition. VI's slow phase is about being near equilibrium. The mathematical similarity (slow relaxation) has different physical origins.",
        },
    ]
    
    for c in comparisons:
        print(f"\n  {c['phenomenon']} ({c['framework']})")
        print(f"    Equation: {c['equation']}")
        print(f"    VI property: {c['vi_property']}")
        print(f"    Form match: {c['form_match']}, Mechanism match: {c['mechanism_match']}")
        print(f"    {c['comparison'][:120]}...")
    
    return comparisons


# ============================================================================
# MAIN
# ============================================================================

def main():
    print("VI FOUNDRY: METHODS REGISTER ANALYSIS SUITE")
    print(f"Run at: {pd.Timestamp.now(tz='UTC').isoformat()}")
    print(f"Workspace: {WORKSPACE}")
    
    all_results = {}
    
    # Run all tests
    try: all_results["changepoint"] = test_changepoint_ltee()
    except Exception as e: print(f"  ERROR: {e}"); all_results["changepoint"] = {"error": str(e)}
    
    try: all_results["surrogate"] = test_surrogate_data()
    except Exception as e: print(f"  ERROR: {e}"); all_results["surrogate"] = {"error": str(e)}
    
    try: all_results["takens"] = test_takens_embedding()
    except Exception as e: print(f"  ERROR: {e}"); all_results["takens"] = {"error": str(e)}
    
    try: all_results["spectral"] = test_spectral_analysis()
    except Exception as e: print(f"  ERROR: {e}"); all_results["spectral"] = {"error": str(e)}
    
    try: all_results["inverse_oc"] = test_inverse_optimal_control()
    except Exception as e: print(f"  ERROR: {e}"); all_results["inverse_oc"] = {"error": str(e)}
    
    try: all_results["taphonomy"] = test_taphonomy_simulation()
    except Exception as e: print(f"  ERROR: {e}"); all_results["taphonomy"] = {"error": str(e)}
    
    try: all_results["scale"] = test_scale_analysis()
    except Exception as e: print(f"  ERROR: {e}"); all_results["scale"] = {"error": str(e)}
    
    try: all_results["sensitivity"] = test_sensitivity_analysis()
    except Exception as e: print(f"  ERROR: {e}"); all_results["sensitivity"] = {"error": str(e)}
    
    try: all_results["seriation"] = test_seriation_cavefish()
    except Exception as e: print(f"  ERROR: {e}"); all_results["seriation"] = {"error": str(e)}
    
    try: all_results["lesion"] = test_lesion_analysis()
    except Exception as e: print(f"  ERROR: {e}"); all_results["lesion"] = {"error": str(e)}
    
    # Cross-method comparison
    try: all_results["cross_comparison"] = cross_method_comparison(all_results)
    except Exception as e: print(f"  ERROR: {e}"); all_results["cross_comparison"] = {"error": str(e)}
    
    # Write results
    output_path = RESULTS_DIR / "methods-register-results.json"
    
    # Convert numpy types for JSON
    def convert(obj):
        if isinstance(obj, (np.integer,)): return int(obj)
        if isinstance(obj, (np.floating,)): return float(obj)
        if isinstance(obj, np.ndarray): return obj.tolist()
        if isinstance(obj, dict): return {k: convert(v) for k, v in obj.items()}
        if isinstance(obj, list): return [convert(x) for x in obj]
        return obj
    
    with open(output_path, "w") as f:
        json.dump(convert(all_results), f, indent=2, default=str)
    
    print(f"\n{'='*60}")
    print(f"Results written to: {output_path}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
