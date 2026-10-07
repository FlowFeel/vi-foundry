#!/usr/bin/env python3
"""
xenobot-p2i mechanics sanity check — foundry package 2.

Re-runs the public ALife_ZapGPT simulation lineage (Le et al., ALife 2025)
without the local-Ollama VLM scorer, to verify the *mechanical core*:
does the pretrained P2I network + cell environment actually steer collective
behavior differently across natural-language prompts?

Controls: zero vector field, fixed random vector field, and seed-identical
initial conditions across all prompts (so differences are attributable to
the prompt-conditional field, not to initial conditions).

Outputs: JSON metrics + comparison figure to results/xenobot-p2i/.
"""
import json
import os
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import torch
from sentence_transformers import SentenceTransformer

REPO = Path("/home/node/.openclaw/workspace/vi-foundry/xenobot-sim/ALife_ZapGPT")
OUT = Path("/home/node/.openclaw/workspace/vi-foundry/results/xenobot-p2i")
OUT.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(REPO))

from cnn_p2i import CNN_P2I          # noqa: E402
from environment import CellEnvironment  # noqa: E402
from config import *                 # noqa: E402,F403

device = torch.device("cpu")
SEED = 2025
TIMESTEPS = 500

PROMPTS = [
    "assemble the cells",
    "spread out",
    "form two groups",
    "stop moving",
    "cluster tightly together",
]

def run_env(vector_field, seed):
    """Run the environment with identical initial conditions (given seed)."""
    np.random.seed(seed)
    env = CellEnvironment(
        num_cells=NUM_CELLS, width=ENV_WIDTH, height=ENV_HEIGHT,
        grid_size=(GRID_WIDTH, GRID_HEIGHT), cell_radius=CELL_RADIUS,
    )
    env.vector_field = vector_field
    for _ in range(TIMESTEPS):
        env.update()
    pos = np.array([c.position for c in env.cells])
    centroid = pos.mean(axis=0)
    disp = np.sqrt(((pos - centroid) ** 2).sum(axis=1)).mean()  # dispersion
    pair = env.avg_pairwise_distances[-1]                        # mean pairwise dist
    speeds = np.array([np.linalg.norm(c.velocity) for c in env.cells])
    return {
        "final_mean_pairwise_distance": float(pair),
        "dispersion_rms_from_centroid": float(disp),
        "final_mean_speed": float(speeds.mean()),
        "centroid": [float(centroid[0]), float(centroid[1])],
        "positions": pos.tolist(),
    }

def main():
    embedder = SentenceTransformer("all-MiniLM-L6-v2")
    weights = torch.load(REPO / "best_weights.pt", map_location=device)
    p2i = CNN_P2I(output_dim=OUTPUT_DIM).to(device)
    p2i.set_weights(weights)
    p2i.eval()
    print("loaded P2I + weights OK")

    results = {}

    # 1) Prompt-conditioned fields (seeds 0..4 to check stability)
    for seed in range(3):
        for p in PROMPTS:
            emb = embedder.encode([p], convert_to_tensor=True).to(device)
            with torch.no_grad():
                vf = p2i(emb).squeeze(0).cpu().numpy()
            r = run_env(vf, seed)
            results[f"prompt::{p}::seed{seed}"] = {k: v for k, v in r.items() if k != "positions"}

    # 2) Zero-field control
    zero = np.zeros((GRID_WIDTH, GRID_HEIGHT, 2), dtype=float)
    results["control::zero_field"] = {k: v for k, v in run_env(zero, 0).items() if k != "positions"}

    # 3) Fixed random field control
    np.random.seed(1)
    rnd = np.random.uniform(-1, 1, size=(GRID_WIDTH, GRID_HEIGHT, 2))
    results["control::random_field"] = {k: v for k, v in run_env(rnd, 0).items() if k != "positions"}

    # summary table
    rows = []
    for k, v in results.items():
        rows.append({
            "condition": k,
            "mean_pairwise_dist": v["final_mean_pairwise_distance"],
            "dispersion": v["dispersion_rms_from_centroid"],
            "mean_speed": v["final_mean_speed"],
        })
    rows.sort(key=lambda r: r["mean_pairwise_dist"])
    with open(OUT / "mechanics_metrics.json", "w") as f:
        json.dump(rows, f, indent=2)
    for r in rows:
        print(f"{r['condition']:<40s} pair={r['mean_pairwise_dist']:7.1f}  disp={r['dispersion']:7.1f}  speed={r['mean_speed']:5.2f}")

    # figure: final positions per prompt (seed 0) + controls
    fig, axes = plt.subplots(2, 4, figsize=(20, 10))
    axes = axes.flatten()
    conds = [f"prompt::{p}::seed0" for p in PROMPTS] + ["control::zero_field", "control::random_field"]
    for ax, c in zip(axes, conds):
        # re-run to recover positions (metrics json has no positions)
        if c.startswith("prompt"):
            p = c.split("::")[1]
            emb = embedder.encode([p], convert_to_tensor=True).to(device)
            with torch.no_grad():
                vf = p2i(emb).squeeze(0).cpu().numpy()
        elif c == "control::zero_field":
            vf = zero
        else:
            vf = rnd
        pos = np.array(run_env(vf, 0)["positions"])
        ax.scatter(pos[:, 0], pos[:, 1], s=12, alpha=0.8)
        ax.set_title(c.replace("prompt::", "").replace("::seed0", ""), fontsize=10)
        ax.set_xlim(0, ENV_WIDTH); ax.set_ylim(0, ENV_HEIGHT)
        ax.set_aspect("equal"); ax.axis("off")
    for ax in axes[len(conds):]:
        ax.axis("off")
    fig.suptitle("ALife_ZapGPT mechanics: final cell positions, seed-identical init (seed 0)", fontsize=13)
    fig.savefig(OUT / "mechanics_positions.png", bbox_inches="tight", dpi=110)
    plt.close(fig)
    print("saved", OUT / "mechanics_positions.png")

if __name__ == "__main__":
    main()