#!/usr/bin/env python3
"""
Drift-Selection Boundary Simulation — Genealogy Stage 5 (falsified)

Wright-Fisher simulation measuring the probability that a slightly
advantageous allele fixes in a finite population, as a function of
the selection coefficient δ.

The Wright-Fisher model with selection: a population of N diploid
individuals (2N gene copies) evolves by random drift and selection.
At each generation, the frequency p of the beneficial allele is
updated by:
    p' = Binomial(2N, p_sel) / (2N)
where p_sel = p·(1 + δ) / (p·(1 + δ) + (1 − p)) is the frequency
after selection.

The retention probability P(retain | δ) is the fraction of replicate
simulations in which the beneficial allele fixes (p = 1) after 100
generations. The excess retention probability ρ_sat is defined as:
    ρ_sat = P(retain | δ_max) − P(retain | δ = 0)

This stage is labeled "falsified" — drift-selection dynamics were
originally proposed as a mechanism for the relaxation formula, but
were found to be inconsistent with the empirical data. The code is
preserved for reproducibility and as a historical marker.

Output: JSON with retention probability vs selection coefficient,
ready for the genealogy archive.
"""

import numpy as np
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

SEED = 42
N_GENERATIONS = 100


def wright_fisher_fixation(N, delta, rng):
    """Run one Wright-Fisher simulation with selection.

    Simulates a beneficial allele starting at frequency p = 0.5 in a
    population of N diploid individuals (2N gene copies). The allele
    has selective advantage δ. Returns 1 if the allele fixes (p = 1),
    0 if it goes extinct (p = 0), and the final frequency otherwise.

    Parameters:
        N: population size (diploid individuals)
        delta: selective advantage of the beneficial allele
        rng: numpy random Generator instance

    Returns:
        int: 1 if fixed, 0 if extinct, or final frequency
    """
    p = 0.5

    for _ in range(N_GENERATIONS):
        if delta > 0:
            p_sel = p * (1.0 + delta) / (p * (1.0 + delta) + (1.0 - p))
        else:
            p_sel = p

        count = rng.binomial(2 * N, p_sel)
        p = count / (2.0 * N)

        if p <= 0.0 or p >= 1.0:
            break

    return 1 if p >= 1.0 else 0


def run_drift_selection_simulation(N=100, n_reps=1000, n_delta=20,
                                   delta_range=(0.0, 0.1)):
    """Run the drift-selection boundary simulation.

    For each value of δ, runs n_reps replicate Wright-Fisher simulations
    and computes the retention (fixation) probability.

    Parameters:
        N: population size. Default 100.
        n_reps: replicates per δ value. Default 1000.
        n_delta: number of δ values. Default 20.
        delta_range: (δ_min, δ_max). Default (0, 0.1).

    Returns:
        dict with structure:
            values: n_reps, N, rho_sat
            metadata: seed, data, params, generator, converged
            data: list of dicts with delta, retention_prob, N, stage
    """
    rng = np.random.default_rng(SEED)

    deltas = np.linspace(delta_range[0], delta_range[1], n_delta)
    retention_probs = np.zeros(n_delta)

    for d_idx in range(n_delta):
        delta = deltas[d_idx]
        retained = 0

        for _ in range(n_reps):
            retained += wright_fisher_fixation(N, delta, rng)

        retention_probs[d_idx] = retained / n_reps

    rho_sat = retention_probs[-1] - retention_probs[0]

    result = {
        "values": {
            "n_reps": n_reps,
            "N": N,
            "rho_sat": float(rho_sat),
        },
        "metadata": {
            "seed": SEED,
            "data": [
                {
                    "delta": float(d),
                    "retention_prob": float(r),
                    "N": N,
                    "stage": "drift_selection",
                }
                for d, r in zip(deltas, retention_probs)
            ],
            "params": {
                "N": N,
                "n_reps": n_reps,
                "n_delta": n_delta,
                "delta_range": list(delta_range),
            },
            "generator": "generate_drift_selection",
            "converged": True,
        },
    }

    return result


if __name__ == "__main__":
    result = run_drift_selection_simulation()

    output_path = os.path.join(RESULTS_DIR, "genealogy-drift-selection-results.json")
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    data = result["metadata"]["data"]
    print(f"{'='*60}")
    print(f"GENEALOGY STAGE 5: DRIFT-SELECTION BOUNDARY")
    print(f"{'='*60}")
    print(f"Population size: N = {result['values']['N']}")
    print(f"Replicates per δ: {result['values']['n_reps']}")
    print(f"Generations: {N_GENERATIONS}")
    print(f"δ range: {data[0]['delta']:.4f} to {data[-1]['delta']:.4f}")
    print(f"Retention at δ = 0: {data[0]['retention_prob']:.4f}")
    print(f"Retention at δ_max: {data[-1]['retention_prob']:.4f}")
    print(f"ρ_sat = {result['values']['rho_sat']:.4f}")
    print(f"Seed: {SEED}")
    print(f"Status: falsified (historical, preserved for reproducibility)")
    print(f"\nResults: {output_path}")