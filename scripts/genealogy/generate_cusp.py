#!/usr/bin/env python3
"""
Thom Cusp Catastrophe — Genealogy Stage 3

Computes equilibrium points of the canonical cusp catastrophe
potential V(x) = x⁴/4 + a·x²/2 + b·x by finding the real roots
of the cubic equation dV/dx = x³ + a·x + b = 0.

The bifurcation set is defined by 4·a³ + 27·b² = 0, which separates
the parameter space into regions with one or three real equilibria.

Region | Discriminant | Real Equilibria
-------|-------------|-----------------
Bifold | 4a³ + 27b² > 0 | 1 (monostable)
Cusp   | 4a³ + 27b² < 0 | 3 (bistable, inner two unstable)
Fold   | 4a³ + 27b² = 0 | 2 (saddle-node bifurcation)

When three real roots exist, they are computed via the trigonometric
solution (Vieta's substitution) for the depressed cubic.

Output: JSON with equilibrium points over the (a, b) parameter plane,
identifying points on or near the bifurcation set. Ready for the
genealogy chain: Ising → Landau → Cusp → Relaxation.
"""

import numpy as np
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

SEED = 42
BIFURCATION_TOLERANCE = 0.1


def cusp_potential(x, a, b):
    """Cusp catastrophe potential V(x) = x⁴/4 + a·x²/2 + b·x.

    Parameters:
        x: state variable
        a: splitting parameter (controls bistability)
        b: bias parameter (controls asymmetry)

    Returns:
        V: potential value at x
    """
    return x**4 / 4.0 + a * x**2 / 2.0 + b * x


def cubic_discriminant(a, b):
    """Compute the discriminant of the cubic x³ + a·x + b = 0.

    The cubic discriminant is Δ = −(4·a³ + 27·b²).
    Δ > 0 → three real roots (bistable region)
    Δ = 0 → double root (bifurcation set)
    Δ < 0 → one real root (monostable region)

    Parameters:
        a: linear coefficient of the cubic
        b: constant term of the cubic

    Returns:
        Δ: cubic discriminant
    """
    return -(4.0 * a**3 + 27.0 * b**2)


def solve_cubic_one_root(a, b):
    """Find the single real root of x³ + a·x + b = 0 (Δ < 0 case).

    Uses numpy's polynomial root finder and extracts the real root.

    Parameters:
        a: linear coefficient
        b: constant term

    Returns:
        list of one real root [x]
    """
    # Coefficients: x³ + 0·x² + a·x + b = 0
    roots = np.roots([1.0, 0.0, a, b])
    real_roots = [np.real(r) for r in roots if abs(np.imag(r)) < 1e-6]
    return real_roots


def solve_cubic_three_roots(a, b):
    """Find the three real roots of x³ + a·x + b = 0 (Δ ≥ 0 case).

    Uses the trigonometric solution (Vieta's substitution) for the
    depressed cubic. For a = 0, falls back to the x³ + b = 0 case.

    Parameters:
        a: linear coefficient (must be ≤ 0 for three real roots)
        b: constant term

    Returns:
        list of three real roots [x₁, x₂, x₃]
    """
    if abs(a) < 1e-10:
        # x³ + b ≈ 0 — approximate roots
        b_cuberoot = np.copysign(np.abs(b) ** (1.0 / 3.0), b)
        return [-b_cuberoot, 0.0, b_cuberoot]
    else:
        # Trigonometric solution for 4a³ + 27b² ≤ 0 (a < 0)
        phi = np.arccos(3.0 * b / (2.0 * a) * np.sqrt(-3.0 / a)) / 3.0
        m = 2.0 * np.sqrt(-a / 3.0)
        return [
            m * np.cos(phi),
            m * np.cos(phi - 2.0 * np.pi / 3.0),
            m * np.cos(phi - 4.0 * np.pi / 3.0),
        ]


def run_cusp_simulation(n_a=50, n_b=50, a_range=(-2.0, 2.0), b_range=(-2.0, 2.0)):
    """Run the cusp catastrophe equilibrium computation.

    Scans the (a, b) parameter plane, computing real equilibria of
    V(x) = x⁴/4 + a·x²/2 + b·x at each point.

    Parameters:
        n_a: number of 'a' values. Default 50.
        n_b: number of 'b' values. Default 50.
        a_range: (a_min, a_max). Default (-2, 2).
        b_range: (b_min, b_max). Default (-2, 2).

    Returns:
        dict with structure:
            values: n_points, bifurcation_eq, n_on_bifurcation
            metadata: seed, data, params, generator, converged
            data: list of dicts with a, b, x_eq, V_eq,
                  on_bifurcation_set, n_equilibria, stage
    """
    np.random.seed(SEED)

    a_vals = np.linspace(a_range[0], a_range[1], n_a)
    b_vals = np.linspace(b_range[0], b_range[1], n_b)
    results = []

    for a in a_vals:
        for b in b_vals:
            D = cubic_discriminant(a, b)

            if D < 0:
                # One real root
                x_roots = solve_cubic_one_root(a, b)
                n_equilibria = 1
            else:
                # Three real roots (or a double root at D = 0)
                x_roots = solve_cubic_three_roots(a, b)
                n_equilibria = 3

            for x in x_roots:
                V = cusp_potential(x, a, b)
                bif_dist = abs(4.0 * a**3 + 27.0 * b**2)
                results.append({
                    "a": float(a),
                    "b": float(b),
                    "x_eq": float(x),
                    "V_eq": float(V),
                    "on_bifurcation_set": bool(bif_dist < BIFURCATION_TOLERANCE),
                    "n_equilibria": n_equilibria,
                    "stage": "cusp",
                })

    result = {
        "values": {
            "n_points": len(results),
            "bifurcation_eq": "4a^3 + 27b^2 = 0",
            "n_on_bifurcation": sum(1 for r in results if r["on_bifurcation_set"]),
        },
        "metadata": {
            "seed": SEED,
            "data": results,
            "params": {
                "n_a": n_a,
                "n_b": n_b,
                "a_range": list(a_range),
                "b_range": list(b_range),
            },
            "generator": "generate_cusp",
            "converged": True,
        },
    }

    return result


if __name__ == "__main__":
    result = run_cusp_simulation()

    output_path = os.path.join(RESULTS_DIR, "genealogy-cusp-results.json")
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    data = result["metadata"]["data"]
    n_on_bif = result["values"]["n_on_bifurcation"]
    n_three = sum(1 for r in data if r["n_equilibria"] == 3)
    n_one = sum(1 for r in data if r["n_equilibria"] == 1)

    print(f"{'='*60}")
    print(f"GENEALOGY STAGE 3: CUSP CATASTROPHE")
    print(f"{'='*60}")
    print(f"Parameter grid: a in [{data[0]['a']:.1f}, {data[-1]['a']:.1f}], "
          f"b in [{data[0]['b']:.1f}, {data[-1]['b']:.1f}]")
    print(f"Total equilibrium points: {result['values']['n_points']}")
    print(f"  Three-equilibria points: {n_three}")
    print(f"  One-equilibrium points:  {n_one}")
    print(f"  On bifurcation set:      {n_on_bif}")
    print(f"Bifurcation equation: {result['values']['bifurcation_eq']}")
    print(f"Seed: {SEED}")
    print(f"\nResults: {output_path}")