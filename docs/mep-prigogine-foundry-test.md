---
uri: vi-foundry/docs/mep-prigogine-foundry-test
owner: edphos
status: living
updated: 2026-08-24
---

# MEP/Prigogine Foundry Test — Valence Ingression Gradient and Latent Valence

## The Test

Can we detect Maximum Entropy Production (MEP) signatures in biological relaxation data? Specifically: do organisms at niche-defined equilibrium (ρ_eq) have measurably different entropy production than organisms displaced from equilibrium (θ > 0)?

## Jan's Insight: The Seed

A seed can sit in soil for 200 years — inert, no metabolic activity, no entropy production. Then it germinates. The "becoming" is instantaneous (germination), but the valence ingression gradient was latent the whole time. The seed carries the capacity to relax toward the niche-defined equilibrium, but it doesn't activate until the conditions trigger it.

This means: **valence is not always active.** The valence ingression gradient can be inert — present in the organism's structure but not producing entropy until the system enters the "becoming" stage (germination, niche entry, environmental trigger).

This has a direct physical analogue: **activation energy.** In chemistry, a reaction may be thermodynamically favorable (negative ΔG) but kinetically blocked (high activation energy). The system carries the potential to react, but doesn't until the barrier is overcome (catalyst, temperature, concentration).

The seed is a biological catalyst-waiting system. The valence is there (the genome encodes the capacity set), the attractor is there (the niche), but the activation barrier (dormancy) prevents relaxation. When the barrier is removed (water, temperature, light), the system relaxes toward equilibrium.

## What This Means for MEP

If valence-seeking IS MEP, then:

1. **Active valence** (organism in the "becoming" stage, relaxing toward ρ_eq) should show measurable entropy production that is higher than organisms at equilibrium (ρ_eq reached) or organisms with dormant valence (seeds, spores, cysts).

2. **The entropy production rate should follow the bi-exponential.** When a seed germinates and enters a new niche, the organism's entropy production should spike (k₁ — fast metabolic reorganization) and then decay (k₂ — slow refinement toward steady state).

3. **The floor (ρ_eq) should be a steady-state entropy production rate.** When the organism reaches niche-defined equilibrium, its entropy production should stabilize at a characteristic rate for that niche. Different niches → different steady-state entropy production.

4. **Dormant valence should show near-zero entropy production.** Seeds, spores, cysts, cryptobiosis (tardigrades) — these systems carry the capacity for valence-seeking but their entropy production is near zero. The valence ingression gradient is latent, not active.

## Foundry Test Design

### Test M1: Entropy Production Rate During Niche Commitment

**System:** Endosymbiont genome reduction (the cleanest VI system).

**Question:** Does the rate of genome reduction correlate with the rate of entropy production change?

**Method:**
1. For endosymbiont lineages with time-calibrated divergence (Buchnera, Carsonella, etc.), estimate the metabolic rate (entropy production proxy) at each time point.
2. Metabolic rate can be estimated from: (a) genome-encoded metabolic pathway completeness, (b) host-dependence level (Fisher et al. 2017), (c) codon usage bias (correlates with expression level and metabolic activity).
3. Fit the bi-exponential to: (a) genome size vs. time (the standard VI test — already done), (b) metabolic pathway completeness vs. time (entropy production proxy), (c) codon usage bias vs. time.
4. If all three follow the same bi-exponential with similar rate constants, the relaxation is coupled — genome reduction and metabolic reorganization are the same process viewed from different angles.

**Prediction from MEP:** All three should follow the same bi-exponential. The rate constants should be similar because they're all measuring the same underlying relaxation (entropy production approach to MEP state).

**Prediction from "same form, different mechanism":** Genome reduction might follow one rate, metabolic reorganization another. If they decouple, the dynamics are not thermodynamic — they're biological (different processes at different rates).

### Test M2: Dormant vs. Active Valence

**System:** Seeds with known dormancy periods.

**Question:** Does the valence ingression gradient (measured as genome-niche mismatch, θ) predict germination timing?

**Method:**
1. For plant species with variable dormancy (e.g., lotus seeds — 200+ year dormancy documented), measure: (a) genome size, (b) metabolic gene repertoire, (c) environmental niche breadth.
2. The prediction: species with higher θ (larger mismatch between carried capacity and niche demand) should have longer dormancy or slower germination, because more reorganization is needed before the organism can function in the niche.
3. Alternatively: species with higher θ should show more transcriptomic change during germination (more genes differentially expressed), because more capacity reallocation is needed.

**Jan's seed insight applied:** The 200-year dormant seed has θ > 0 (it carries capacities mismatched to the soil environment) but its entropy production is ~0. The valence ingression gradient is latent. When germination triggers, entropy production spikes and the system begins relaxing toward ρ_eq. The seed's genome doesn't change during dormancy — θ is constant. But the activation (germination) converts latent valence into active valence.

**This is the biological analogue of activation energy.** The Arrhenius equation: k = A·e^(−Ea/RT). In chemistry, the rate depends on temperature (T) because temperature determines whether the activation barrier is overcome. In biology, the "temperature" is the environmental trigger (water, light, temperature, chemical signal) that lifts dormancy. Below the trigger threshold, k = 0 (latent valence). Above it, k > 0 (active valence).

### Test M3: S+A Decomposition of Trait-Loss Dynamics

**System:** The foundry's existing relaxation data (LTEE, endosymbionts, Orobanchaceae).

**Question:** Is the trait-loss Jacobian purely dissipative (S >> A, thermodynamic character) or does it have a rotational component (A ≠ 0, non-dissipative)?

**Method:**
1. Compute the Jacobian of the trait-loss dynamics. For the bi-exponential dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂), the Jacobian is:
   J = ∂(dρ/dt)/∂ρ = −(k₁ + k₂)
   This is a scalar (1×1 matrix) for a single trait. The S+A decomposition of a scalar: S = J (symmetric), A = 0 (no antisymmetric component).
2. For multi-trait systems (e.g., endosymbiont gene loss across multiple gene categories), the Jacobian becomes a matrix. J_ij = ∂(dρ_i/dt)/∂ρ_j. If traits are independent: J is diagonal (purely dissipative). If traits interact: J has off-diagonal terms.
3. Decompose J = S + A. S (symmetric) = dissipative component. A (antisymmetric) = rotational/circulatory component.
4. **Prediction from MEP:** A ≈ 0 (purely dissipative — thermodynamic relaxation). S dominates.
5. **Prediction from "same form, different mechanism":** A ≠ 0 (biological dynamics have circulatory components — feedback loops, cross-talk, pleiotropy that create non-dissipative dynamics).

**Infrastructure:** The `equilibria` package's `decomposition/solver.py` already implements this decomposition. Feed it the multi-trait Jacobian and it returns S, A, and the field classification (conservative, non-conservative, dissipative).

### Test M4: Entropy Production in Cavefish (Connecting R1 and MEP)

**System:** Astyanax cavefish — surface vs. cave populations.

**Question:** Do cavefish at niche equilibrium (long-established cave populations) have different metabolic rates (entropy production) than surface fish or recently-colonized cave populations?

**Method:**
1. Measure metabolic rate (O₂ consumption, a direct entropy production proxy) in: surface fish, recently-colonized cave populations (Molino — younger), and long-established cave populations (Pachón, Tinaja — older).
2. **Prediction from MEP:** Surface fish have high metabolic rate (full capacity, high entropy production). Recently-colonized cavefish have intermediate rate (mid-relaxation). Long-established cavefish have the lowest rate (at ρ_eq, minimum entropy production for the cave niche).
3. The metabolic rate should follow the bi-exponential: fast initial drop (k₁) then slow decline (k₂) toward the cave-niche equilibrium.

**Note:** This connects to R1. The R1 test found STRING degree doesn't predict loss order. But metabolic rate (entropy production) might. If the ordering follows metabolic cost rather than network degree, the dynamics are cost-benefit (Optimal Control) rather than structural (integration depth).

## The Latent Valence Concept

Jan's seed insight introduces a crucial distinction:

**Active valence:** The organism is in the "becoming" stage — relaxing toward ρ_eq, producing entropy, changing. The rate law applies. k₁ and k₂ are non-zero.

**Latent valence:** The organism carries the capacity to relax toward ρ_eq, but is dormant. The rate law doesn't apply (k = 0). The valence ingression gradient is present in the genome (θ > 0) but not active. No entropy production. No trait change.

**Activated valence:** The transition from latent to active — germination, niche entry, environmental trigger. The activation barrier is overcome. The rate law "turns on."

This maps to the Arrhenius framework:
- **Latent:** Below activation barrier. k = 0. System carries potential but doesn't react.
- **Activated:** Barrier overcome. k > 0. System relaxes toward equilibrium.
- **Active:** Relaxation in progress. dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂).
- **Equilibrium:** ρ = ρ_eq. dρ/dt = 0. Entropy production at steady state.

The seed in soil for 200 years is in the **latent** state. The valence is there (the genome encodes the niche-defined capacity set), but the activation barrier (dormancy) prevents relaxation. Germination is the **activation** event. Post-germination growth and development are the **active** relaxation. The mature plant at niche equilibrium is at **ρ_eq**.

This is a four-state model: latent → activated → active → equilibrium.

## What This Tells Us About the Department

The activation energy concept is from **chemical kinetics**. The four-state model (latent → activated → active → equilibrium) is exactly how chemical reactions work: reactants carry the potential to react (latent), overcome the activation barrier (activated), react (active relaxation), reach equilibrium.

If the biological valence-seeking follows this pattern — and the seed example shows it does — then the dynamics ARE chemical kinetics. Not analogy. Identity. The same four-state model, the same activation barrier, the same relaxation equation.

The question is whether the equilibrium (ρ_eq) is a thermodynamic state (MEP) or a functional state (cost-benefit). The seed doesn't resolve this — it shows the dynamics are chemical-kinetic, but the attractor could still be either thermodynamic or functional.

The M3 test (S+A decomposition) is the one that would resolve it. If the trait-loss Jacobian is purely dissipative (A = 0), the dynamics are thermodynamic. If it has rotational components (A ≠ 0), there are non-dissipative biological processes (feedback, cross-talk) that don't have a chemical analogue.

## Priority

| Test | What it establishes | Data ready? |
|------|---------------------|-------------|
| M1 | Entropy production follows bi-exponential | Yes — endosymbiont genomes + metabolic data |
| M2 | Latent vs. active valence (seed germination) | Partial — dormancy data in literature |
| M3 | S+A decomposition — dissipative vs. rotational | Yes — existing foundry data + equilibria package |
| M4 | Metabolic rate in cavefish | Partial — metabolic rate data in literature |

M3 is the highest-priority test. It uses existing infrastructure (equilibria package) and existing data (foundry relaxation data). It directly answers: are the dynamics purely dissipative (thermodynamic) or not?

## Connection to R6 Result

The R6 C4 inbound test came back: **bi-exponential NOT supported.** Single exponential wins (ΔAIC = 3.96). k₁ collapsed to k₂ — the two rate constants are indistinguishable.

This is informative for the MEP question:

- If the inbound trajectory is single-exponential (not bi-exponential), the dynamics are **monophasic** for capacity gain.
- The outbound trajectory (LTEE) is bi-exponential — **biphasic** for capacity loss.
- **Asymmetry confirmed.** Inbound (gain) is monophasic. Outbound (loss) is biphasic.

What does this mean?
- In chemistry, forward and reverse reactions are related by the equilibrium constant: k_forward / k_reverse = K_eq. The rates are different but the functional form is the same (both first-order).
- In VI, the functional form is DIFFERENT: outbound is bi-exponential (two channels), inbound is single-exponential (one channel). This is not what chemical relaxation looks like.
- This supports **"same form (for loss), different mechanism"** — the dynamics are NOT symmetric. The thermodynamic identity claim weakens.

But: n=8 is very low power. The bi-exponential might be there but undetectable. The single-exponential fit is excellent (R² = 0.997) and the rate constant (k = 0.169 My⁻¹) is clean, but the power to distinguish k₁ ≠ k₂ with 8 points and 4 parameters is extremely low.

The honest conclusion: we cannot confirm symmetry (would support thermodynamic identity), and we cannot confirm asymmetry (would support different mechanism). The data are insufficient. But the point estimate favors monophasic inbound, which is asymmetric with the biphasic outbound.
