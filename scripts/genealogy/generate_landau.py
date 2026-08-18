#!/usr/bin/env python3
"""
Landau Mean-Field Free Energy — Genealogy Stage 2

Computes the equilibrium magnetization M_eq by minimizing the Landau
free energy density over a grid of M values.

Free energy:
    F(M) = a·M² + b·M⁴ + h·M

The parameter 'a' controls the phase transition: a > 0 gives a single
minimum at M = 0 (disordered/paramagnetic phase), while a < 0 gives
two symmetric minima (ordered/ferromagnetic phase). The quartic term
b > 0 ensures stability. The field h breaks symmetry.

The normalized temperature T_norm = a + 1 maps the control parameter
to a temperature-like scale: T_norm = 1 at a = 0 (the critical point).

Output: JSON with equilibrium magnetization vs a (and T_norm), ready
for the genealogy chain: Ising → Landau → Cusp → Relaxation.
"""

import numpy as np
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

SEED = 42


def landau_free_energy(M, a, b, h):
    """Landau free energy density F(M) = a·M² + b·M⁴ + h·M.

    Parameters:
        M: magnetization array
        a: quadratic coefficient (controls phase transition sign)
        b: quartic coefficient (must be > 0 for stability)
        h: external field (breaks symmetry)

    Returns:
        F: free energy density at each M
    """
    return a * M**2 + b * M**4 + h * M


def find_equilibrium(M_grid, a, b, h):
    """Find the magnetization that minimizes F(M) on a grid.

    Parameters:
        M_grid: array of trial M values
        a: quadratic coefficient
        b: quartic coefficient
        h: external field

    Returns:
        (M_eq, F_min): equilibrium magnetization and minimum free energy
    """
    F = landau_free_energy(M_grid, a, b, h)
    eq_idx = np.argmin(F)
    return M_grid[eq_idx], F[eq_idx]


def run_landau_simulation(n_points=100, a_range=(-1.0, 1.0), b=1.0, h=0.0):
    """Run the Landau free energy minimization.

    For each value of 'a' in a_range, finds M_eq that minimizes F(M).

    Parameters:
        n_points: number of 'a' values to sample. Default 100.
        a_range: (a_min, a_max). Default (-1, 1).
        b: quartic coefficient. Default 1.0.
        h: external field. Default 0.0.

    Returns:
        dict with structure:
            values: summary values (n_points, b, h)
            metadata: full results and params (seed, data, params, generator)
            data: list of dicts with a, M_eq, F_min, T_norm, b, h, stage
    """
    np.random.seed(SEED)

    a_vals = np.linspace(a_range[0], a_range[1], n_points)
    M_grid = np.linspace(-1.5, 1.5, 200)
    M_eq = np.zeros(n_points)
    F_min = np.zeros(n_points)

    for i in range(n_points):
        a = a_vals[i]
        M_eq[i], F_min[i] = find_equilibrium(M_grid, a, b, h)

    T_norm = a_vals + 1.0

    result = {
        "values": {
            "n_points": n_points,
            "b": b,
            "h": h,
        },
        "metadata": {
            "seed": SEED,
            "data": [
                {
                    "a": float(a),
                    "M_eq": float(m),
                    "F_min": float(f),
                    "T_norm": float(t),
                    "b": b,
                    "h": h,
                    "stage": "landau",
                }
                for a, m, f, t in zip(a_vals, M_eq, F_min, T_norm)
            ],
            "params": {
                "n_points": n_points,
                "a_range": list(a_range),
                "b": b,
                "h": h,
            },
            "generator": "generate_landau",
            "converged": True,
        },
    }

    return result


if __name__ == "__main__":
    result = run_landau_simulation()

    output_path = os.path.join(RESULTS_DIR, "genealogy-landau-results.json")
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    data = result["metadata"]["data"]
    # Find critical point (a = 0, where M_eq jumps from 0 to nonzero)
    non_zero = [d for d in data if abs(d["M_eq"]) > 0.01]

    print(f"{'='*60}")
    print(f"GENEALOGY STAGE 2: LANDAU FREE ENERGY")
    print(f"{'='*60}")
    print(f"b = {result['values']['b']}, h = {result['values']['h']}")
    print(f"a range: {data[0]['a']:.2f} to {data[-1]['a']:.2f}")
    print(f"Points: {len(data)}")
    print(f"Ordered phase (|M_eq| > 0.01): {len(non_zero)}/{len(data)} points")
    if non_zero:
        print(f"  M_eq at a = {non_zero[0]['a']:.2f}: {non_zero[0]['M_eq']:.4f}")
        print(f"  M_eq at a = {non_zero[-1]['a']:.2f}: {non_zero[-1]['M_eq']:.4f}")
    print(f"Disordered phase (M_eq ≈ 0): {len(data) - len(non_zero)}/{len(data)} points")
    print(f"Seed: {SEED}")
    print(f"\nResults: {output_path}")