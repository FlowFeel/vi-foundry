#!/usr/bin/env python3
"""
Cortés-Poza 2026 (JMB 93:43) — reproduction run against the public implementation
(github.com/YuririaCP/bioelectricity).

Targets the paper's headline numerical claims:
  E1  Nucleation threshold: ppat≈0 below δ≲0.7; ppat≈0.53 near δ*≈1.9-2.0 (N=20, T=60)
  E2  Regeneration: fidelity ≥0.95 for lesion fractions {0.1,0.3,0.5,0.7}, G_init=0.5
  B3  Basin boundary: f*≈0.5 (1D chain, G=0.3, a=1.2)
  B2  Polarity reversal: A=2.5, T_force=12 switches BOTH memory regimes permanently
  B5  Switching phase diagram: A*(T_force)≈2.0-2.5 for T_force ≳ 6
  B1  Lyapunov descent: ΔE < 0 (pure + full model)

Also: numerically evaluates the paper's §5.1 energy-barrier formula
√(2·(a/4)(V0−V−)²(V+−V−)²) — claimed ≈1.74.
"""
import os
import sys

REPO = "/home/node/.openclaw/workspace/vi-foundry/xenobot-p2i/cortes-poza/bioelectricity"
OUT = "/home/node/.openclaw/workspace/vi-foundry/results/xenobot-p2i/cortes-poza"
os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, "figures"), exist_ok=True)
sys.path.insert(0, REPO)
os.chdir(REPO)

import numpy as np

print("=" * 70)
print("REPRODUCTION RUN — Cortés-Poza 2026, JMB 93:43")
print("=" * 70)

# --- 0. Energy-barrier formula check (§5.1) -------------------------------
a, Vm, V0, Vp = 1.2, -1.5, 0.0, 1.5
DeltaU_correct = 81 * a / 64
formula_val = (a / 4) * (V0 - Vm) ** 2 * (Vp - Vm) ** 2
print(f"\n[0] Energy-barrier formula check")
print(f"    Correct ΔU (=81a/64)  = {DeltaU_correct:.4f}  -> δ* = √(2ΔU) = {np.sqrt(2*DeltaU_correct):.3f}")
print(f"    Paper §5.1 formula (a/4)(V0−V−)²(V+−V−)² = {formula_val:.4f} -> √(2·formula) = {np.sqrt(2*formula_val):.3f}")
print(f"    Paper claims δ* ≈ 1.74. Formula evaluates to {np.sqrt(2*formula_val):.3f} — MISMATCH factor {formula_val/DeltaU_correct:.0f} in ΔU")

# --- 1. Nucleation threshold (Experiment 1) -------------------------------
from validation_experiments import experiment_nucleation_threshold

print(f"\n[1] Nucleation threshold — paper params: N=20, T=60, δ∈[0.3,2.5], 15 seeds")
c1 = experiment_nucleation_threshold(
    N=20, T=60.0,
    delta_vals=np.linspace(0.3, 2.5, 12),
    n_seeds=15,
    save_path=os.path.join(OUT, "figures", "repro_nucleation.png"))
for d, p in zip(c1["delta_vals"], c1["p_pattern"]):
    flag = " <-- δ* claimed 1.9-2.0, ppat≈0.53" if 1.8 <= d <= 2.1 else ""
    print(f"    δ={d:5.2f}  ppat={p:6.3f}  frac_plus={c1['frac_plus'][np.where(c1['delta_vals']==d)[0][0]]:5.3f}{flag}")

# --- 2. Regeneration (Experiment 2) ---------------------------------------
from validation_experiments import experiment_regen_vs_lesion

print(f"\n[2] Regeneration — paper params: lesion ∈ {{0.1,0.3,0.5,0.7}}, G_init=0.5, Teq=35, Tregen=60")
c2 = experiment_regen_vs_lesion(
    N=30, T_eq=35.0, T_regen=60.0,
    lesion_fracs=np.array([0.1, 0.3, 0.5, 0.7]),
    n_seeds=10,
    params_override={"G_init": 0.5},
    label="Full model (paper params)",
    save_path=os.path.join(OUT, "figures", "repro_regen.png"))
print("    result dict keys:", list(c2.keys()))
for k, v in c2.items():
    if isinstance(v, np.ndarray):
        print(f"    {k} = {np.round(v, 4)}")
    else:
        print(f"    {k} = {v}")

# --- 3. Basin boundary (f* ≈ 0.5) -----------------------------------------
from attractor_analysis import experiment_basin_mapping

print(f"\n[3] Basin mapping — N=16, G=0.3, a=1.2, 15 fractions, 3 seeds")
c3 = experiment_basin_mapping(
    N=16, T_eq=50.0,
    depol_fracs=np.linspace(0.0, 1.0, 15),
    n_seeds=3,
    save_path=os.path.join(OUT, "figures", "repro_basin.png"))
print("    frac -> final mean V (per seed)")
for i, f in enumerate(c3["depol_fracs"]):
    print(f"    f={f:5.2f}  <V>={np.round(c3['final_V_means'][i], 3)}  pol={np.round(c3['pol_mean'][i], 3)}±{np.round(c3['pol_std'][i], 3)}")

# --- 4. Polarity reversal (memory regimes) --------------------------------
from attractor_analysis import experiment_polarity_reversal

print(f"\n[4] Polarity reversal — N=16, A=2.5, T_force=12, with(50)/without(0.3) memory")
c4 = experiment_polarity_reversal(
    N=16, T_eq=50.0, T_force=12.0, T_post=70.0,
    amplitude=2.5,
    tau_eps_with=50.0, tau_eps_without=0.3,
    save_path=os.path.join(OUT, "figures", "repro_polarity.png"))
wm, wom = c4["with_memory"], c4["without_memory"]
import json
print("    with_memory    :", json.dumps({k: (round(v, 4) if isinstance(v, float) else v) for k, v in wm.items() if not isinstance(v, np.ndarray)}, default=str)[:400])
print("    without_memory :", json.dumps({k: (round(v, 4) if isinstance(v, float) else v) for k, v in wom.items() if not isinstance(v, np.ndarray)}, default=str)[:400])

# --- 5. Lyapunov descent --------------------------------------------------
from attractor_analysis import experiment_lyapunov_verification

print(f"\n[5] Lyapunov verification — N=25, T=50")
c5 = experiment_lyapunov_verification(N=25, T=50.0)
for label, res in c5.items():
    E = res['E']
    print(f"    {label}: ΔE = {E[-1] - E[0]:.4f} ({'DESCENDS ✓' if E[-1] - E[0] < 0 else 'RISES ✗'}); E0={E[0]:.4f}, Ef={E[-1]:.4f}")

print("\n[6] Switching phase diagram — N=16, A∈[0.5,4], T_force∈[2,20], 3 seeds (may take a few minutes)")
from attractor_analysis import experiment_switching_phase_diagram

c6 = experiment_switching_phase_diagram(
    N=16, T_eq=40.0, T_post=50.0,
    A_vals=np.linspace(0.5, 4.0, 10),
    T_force_vals=np.linspace(2.0, 20.0, 10),
    n_seeds=3)
print("    A_star:", c6['A_star'])
print("    switch_prob matrix (rows=A, cols=T_force):")
for i, A in enumerate(c6['A_vals']):
    print(f"      A={A:4.1f}: " + " ".join(f"{p:.0f}" for p in c6['switch_prob'][i]))

print("\nDONE")