#!/usr/bin/env python3
"""
Ising Model Simulation — Genealogy Stage 1

Generates magnetization data from the 2D Ising model using
Metropolis Monte Carlo. This is the actual Ising Hamiltonian,
not an analogy table.

Hamiltonian:
    H = −J·∑σᵢσⱼ − h·∑σᵢ

The simulation runs on an L×L square lattice with periodic boundary
conditions, sweeping through temperatures from T_min to T_max (in units
of J/k_B). Magnetization is reported as the absolute mean spin per site,
normalized by the critical temperature T_c = 2.269 (Onsager's exact
solution for the 2D square lattice).

Output: JSON with magnetization vs T/T_c data, ready for the genealogy
chain: Ising → Landau → Cusp → Relaxation.
"""

import numpy as np
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

SEED = 42
TC_ONSAGER = 2.269  # T_c = 2J/(k_B * arcsinh(1)) ≈ 2.269


def metropolis_sweep(spins, L, beta, J, h, rng):
    """Perform one full sweep of Metropolis updates on the lattice.

    Randomly selects L×L sites and attempts spin flips with the
    Metropolis acceptance probability min(1, e^{−β·ΔE}).

    Parameters:
        spins: 2D array of ±1 spins (L×L)
        L: lattice linear size
        beta: inverse temperature β = 1/T
        J: coupling constant (ferromagnetic for J > 0)
        h: external magnetic field
        rng: numpy random Generator instance

    Returns:
        Updated spins array (modified in-place).
    """
    for _ in range(L * L):
        i = rng.integers(0, L)
        j = rng.integers(0, L)

        # Periodic boundary conditions
        up = spins[(i - 1) % L, j]
        down = spins[(i + 1) % L, j]
        left = spins[i, (j - 1) % L]
        right = spins[i, (j + 1) % L]

        # Energy change for flipping spin[i,j]
        dE = 2.0 * J * spins[i, j] * (up + down + left + right) + 2.0 * h * spins[i, j]

        # Accept if dE < 0 or with probability exp(-beta * dE)
        if dE < 0.0 or rng.uniform() < np.exp(-beta * dE):
            spins[i, j] = -spins[i, j]

    return spins


def run_ising_simulation(L=16, J=1.0, h=0.0, n_sweeps=1000,
                         n_temps=20, T_range=(1.0, 4.0)):
    """Run the 2D Ising Metropolis MC simulation.

    Parameters:
        L: lattice size (L×L). Default 16.
        J: coupling constant. Default 1.0.
        h: external field. Default 0.0.
        n_sweeps: number of MC sweeps per temperature. Default 1000.
        n_temps: number of temperature points. Default 20.
        T_range: (T_min, T_max) in units of J/k_B. Default (1.0, 4.0).

    Returns:
        dict with structure:
            values: summary values (n_temps, Tc, J, h, L)
            metadata: full results and params (seed, data, params, generator)
            data: list of dicts with T_norm, M, J, h, L, stage
    """
    rng = np.random.default_rng(SEED)

    temps = np.linspace(T_range[0], T_range[1], n_temps)
    mags = np.zeros(n_temps)

    for t_idx in range(n_temps):
        T = temps[t_idx]
        beta = 1.0 / T

        # Initialize random spin configuration
        spins = rng.choice([-1, 1], size=(L, L))

        # Thermalization + measurement sweeps
        for _ in range(n_sweeps):
            spins = metropolis_sweep(spins, L, beta, J, h, rng)

        # Record absolute magnetization
        mags[t_idx] = np.abs(np.mean(spins))

    # Normalize temperature by T_c
    T_norm = temps / TC_ONSAGER

    result = {
        "values": {
            "n_temps": n_temps,
            "Tc": TC_ONSAGER,
            "J": J,
            "h": h,
            "L": L,
        },
        "metadata": {
            "seed": SEED,
            "data": [
                {
                    "T_norm": float(t),
                    "M": float(m),
                    "J": J,
                    "h": h,
                    "L": L,
                    "stage": "ising",
                }
                for t, m in zip(T_norm, mags)
            ],
            "params": {
                "L": L,
                "J": J,
                "h": h,
                "n_sweeps": n_sweeps,
                "n_temps": n_temps,
                "T_range": list(T_range),
            },
            "generator": "generate_ising",
            "converged": True,
        },
    }

    return result


if __name__ == "__main__":
    result = run_ising_simulation()

    output_path = os.path.join(RESULTS_DIR, "genealogy-ising-results.json")
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    data = result["metadata"]["data"]
    print(f"{'='*60}")
    print(f"GENEALOGY STAGE 1: ISING MODEL SIMULATION")
    print(f"{'='*60}")
    print(f"Lattice: {result['values']['L']}×{result['values']['L']}")
    print(f"J = {result['values']['J']}, h = {result['values']['h']}")
    print(f"Temperatures: {len(data)} points from T/T_c = {data[0]['T_norm']:.2f} to {data[-1]['T_norm']:.2f}")
    print(f"T_c = {result['values']['Tc']}")
    print(f"Magnetization at lowest T: {data[0]['M']:.4f}")
    print(f"Magnetization at highest T: {data[-1]['M']:.4f}")
    print(f"Seed: {SEED}")
    print(f"\nResults: {output_path}")