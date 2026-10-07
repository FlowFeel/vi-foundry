# R1 Rebuild: Cavefish Integration-Depth Ordering on Proper Ground

**Date:** 2026-09-05
**Status:** COMPLETE — mixed result, registered
**Supersedes:** withdrawn R1 (`r1-results.md` — developmental-onset label confound,
category-block artifact, no provenance)

## Design fixes vs withdrawn R1

| R1 flaw | Rebuild fix |
|---------|-------------|
| "Loss timing" = hpf developmental onset | Dependent variable = actual regression magnitude from the cave-population age gradient (E7 `trait_comparison_by_age.csv`, 16 populations incl. hybrids) |
| Category-block labels (4 ranks for 22 genes) | Trait-level onset ranking; gene-level only where documented (eye pathway, Jeffery 2009) |
| No provenance for genes/ranks | Documented gene sets: eye (Jeffery 2009, Yoshizawa 2012), pigment (Jeffery 2009), sleep (Jaggard 2018 — hypocretin causal); STRING re-queried live 2026-09-05, Danio rerio 7955, degree = partner count at combined score ≥ 0.4 |
| STRING degree protocol unstated | Degree protocol defined (above); fresh query |

## Gene sets (documented)

| Trait | Genes | Source |
|-------|-------|--------|
| Eye | pax6a, pax6b, rx1, rx2, six3, six6a, cryaa, cryba1, crybb1 | Jeffery 2009; Yoshizawa 2012 |
| Pigment | oca2, mc1r, tyr, mitfa, slc24a5, kit | Jeffery 2009 |
| Sleep | hcrt (hypocretin) | Jaggard 2018 (eLife) |
| Aggression, schooling | — no documented gene list in hand | DATA GAP |

STRING degrees (mean): eye 1.44 (9 genes), pigment 4.4 (5 genes, kit excluded — 0),
sleep 0.0 (hcrt).

## Results

### Test A — trait-level onset from age gradient

Regression magnitude at earliest age (Chica hybrids, 7 kya): **sleep 0.77 > schooling
0.60 > eye 0.55 ≈ pigment 0.55 > aggression 0.50.**

Onset ranking (VI: low integration depth lost first):
1. **sleep** — STRING depth **0.0** ✅ VI-consistent
2. schooling — no gene list (DATA GAP)
3. **eye** — depth 1.44 (mid) ≈
4. **pigment** — depth **4.4 (highest)** ❌ VI-inconsistent — pigment regresses early
   (0.95 by 20 kya) despite being the deepest trait in the set
5. aggression — no gene list (DATA GAP); notable: **never fully regresses** (max 0.80
   even at 525 kya — VI-consistent with a deeply integrated behavioral trait, but
   unscored)

### Test B — behavioral leads morphological (P4 signal)

Sleep (behavior) at 7 kya: 0.77 vs eye (morphology): 0.55. Directionally
consistent with VI's behavior-first prediction (E7's 5/7 hybrids finding), and
hypocretin is a single causal gene (depth 0) — the earliest onset trait has the
lowest integration depth. **But n = 2 at 7 kya** (Chica Pool 1 & 2):
Mann-Whitney p = 0.333, not significant. Signal, not proof.

### Test C — eye pathway gene-level order (Jeffery 2009)

Lens crystallins (cryaa, cryba1, crybb1) = initial molecular trigger → predicted
earliest. Mean STRING depth: **crystallins 1.3 vs regulators (pax6/rx/six) 1.5** —
directionally VI-consistent (the early molecular event is the shallower one) but
n = 9, Spearman ρ = 0.047, p = 0.905; Mann-Whitney p = 0.500. Not significant.

## Verdict

**Mixed, and different from both previous claims.** The withdrawn R1 negative was
unreliable (wrong variable, no provenance). The rebuild does NOT cleanly support
VI either:

- **Consistent:** sleep-first onset with the single causal gene (hcrt) at depth 0;
  behavioral-leads-morphological direction; lens-crystallins-first direction in the
  eye pathway; aggression never fully regressing.
- **Inconsistent:** pigment regresses early (0.95 by 20 kya) despite the highest
  documented depth (4.4) — the same anomaly class that sank R1, now on proper
  grounds. Pigment's oca2/mc1r/tyr are pleiotropic hubs; just as in the withdrawn
  test, high PPI degree does not translate to late loss.
- **Underpowered:** every inferential test here is n ≤ 9 with weak or null p-values.
  The pattern is directional across three independent angles, but not established.

**Interpretation:** STRING PPI degree is not a good operationalization of VI's
integration depth for traits with strong *pleiotropic but lossable* architecture
(pigment). The rebuild's own signal favors a *developmental-substrate* measure
(lens = organizer, hcrt = single causal gene) over network centrality — which is
itself informative: it points Test C's original design (dependency depth in GRN,
not PPI degree) as the metric that should carry the claim.

## Files
- This file: `vi-foundry/results/r1-cavefish-sequence/r1-rebuild.md`
- Raw STRING query: `/tmp/string_network.tsv` (2026-09-05 live query)
- Data: `tools/vi-testing/cavefish-test/` (E7 population data)

## Reporting decision
- **Lab notebook / foundry:** this rebuild with the mixed verdict and the pigment
  anomaly. Honest negative-to-mixed record.
- **Paper:** NOT a quantitative row by itself. The directional behavior-first +
  eye-pathway signals can be cited qualitatively in §7/§8 as "consistent with"
  only if the pigment anomaly is disclosed alongside. The metric lesson
  (PPI degree ≠ integration depth; dependency depth is the right test) goes into
  the R1 re-queue as the design constraint for any future attempt.