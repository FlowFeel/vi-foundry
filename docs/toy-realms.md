# Toy Realms — Speculative Explorers

## What These Are

The toy realms are interactive simulations that explore the VI framework's dynamics in simplified systems. They are not tests of the hypothesis — they are tools for building intuition about how the framework's mechanisms operate. Each realm generates synthetic data from the VI equations and visualizes the trajectory under different parameter settings.

## Realms

### Genome Reduction

Explores the biphasic genome reduction trajectory predicted by the capacity reallocation continuum. Users can adjust the mismatch parameter (M), the integration-depth threshold (θ), and the decay rate (λ) to observe how the trajectory changes. The threshold gate is visible: traits below θ decay to zero while traits above θ are retained at 1.0. This is the structural biphasic signal — not a two-phase rate ratio, but a threshold-gated separation between protected and unprotected components.

**What to look for:** The threshold_biphasicity metric approaches 1.0 when the threshold cleanly separates protected from unprotected traits. At low θ, almost everything is unprotected and the trajectory looks monophasic. At high θ, almost everything is protected and little is shed. The interesting regime is intermediate θ, where the biphasic signal is strongest.

### Irreversibility

Explores the cusp catastrophe that formalizes the specialization trap. Users can trace the forward path (increasing commitment) and the reverse path (decreasing commitment) to observe hysteresis: the system does not return to the ancestral state when the environmental parameter is reversed, because the developmental scaffolding has been reallocated.

**What to look for:** The hysteresis loop — the forward and reverse paths diverge at the bifurcation point. The width of the hysteresis loop is the "commitment depth" that must be traversed before the system can return to the ancestral state. Below the threshold, the system is reversible; above it, it is not.

### Homo Inversion

Explores the macroevolutionary inversion: positively diversity-dependent speciation in *Homo* vs negative diversity-dependence in other vertebrate clades. Users can toggle the substrate parameter (ecological vs cultural) to observe how the sign of diversity-dependence flips. Under ecological substrate, the niche depletes under exploitation (negative diversity-dependence). Under cultural substrate, the niche expands under exploitation (positive diversity-dependence).

**What to look for:** The bifurcation at the substrate shift point. The sign of diversity-dependence is not a parameter that is tuned — it is a structural consequence of whether the substrate depletes or expands under exploitation. This is the mechanism the monograph proposes for the *Homo* macroevolutionary inversion (§3).

### Cross-Kingdom Transfer

Explores the L3 cross-kingdom claim: a parameter measured in one substrate predicts the loss ordering in another. Users can adjust the plant-derived slope and observe how well it predicts the bird morphological ordering. The simulation generates both substrates from the same underlying principle with different friction coefficients.

**What to look for:** The concordance between the plant-predicted ordering and the observed bird ordering. At high friction (very different substrates), the ordering is preserved but the slope magnitude differs — which is what the real data show (plant slope = 0.781, bird slope = 1.000, ρ = 0.755). The ordering claim is the substantive result; the rate claim is not transferable across kingdoms.
