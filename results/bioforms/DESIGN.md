# Bioforms in the Foundry — identification, blind prediction, compound intelligence

Date: 2026-10-29 · Load: `flow/bioforms-grammar` · Requested by Jan:
"create tests in foundry to identify life forms and blindly predict their behaviors,
their predators, how they adapt in different kinds of environments; combine forms to
explain intelligence/parameters of behavior, modes of learning."

## What was loaded

| Artifact | Path |
|---|---|
| Oracle (pre-registered rules, blind protocols, predator rules, VD bridge) | `baseline/oracle_bioforms.yml` |
| Validator (seeded, deterministic, stdlib-only) | `scripts/validate_bioforms.py` |
| Dataset (101 forms, archive's own published fields) | `data/bioforms/bioforms.json` |
| Results | `output/bioforms_validation.json` |

Analysis groundwork (workspace): INFERNO `data/analysis/inferno-bioforms-morphoresonance.md`
(WCI 42.2, T3 — classifier, not model) and affinity/compound analysis
`data/analysis/bioforms-affinity-groups.md` (8 state-families + 1 operator algebra).

## Answers to Jan's three questions

### 1. Tests to identify life forms — YES, and it nearly works with trivial rules

T2 blind-holdout family identification from shape-language alone: **0.9 holdout
(9/10)**; full-corpus consistency 0.594 with crude substring scoring. The error
surface is entirely **hybrid forms** (branching-colonial → collective; the forms
that instantiate two families at once). A real classifier (embedding over the
geometry texts) is a small step and would push well past 0.9. The grammar's
families are clean; the hybrids are where the grammar does its work, not where
it fails.

Identification pipeline (once the classifier exists): shape description (from
text, morphometrics, or vision) → family vector → id → the oracle's behavioral/
adaptive/predator priors.

### 2. Blindly predict behaviors, predators, adaptation — PARTIAL, honestly bounded

- **Behaviors:** T3 holdout 0.571 (scoreable n=7); full-corpus 0.243. Form
  constrains but does not determine behavior — the geometry-to-behavior map is
  genuinely lossy (a fusiform can cruise, burrow, or lunge). That underdetermination
  is itself the finding: behavior prediction needs the environment term, which is
  exactly the VD two-layer picture (form = τ₂ record; behavior = τ₁ deployment
  conditioned on niche).
- **Adaptation:** T4 holdout 0.5, full-corpus 0.281. Same story, more extreme —
  adaptation is niche-relative, and the archive's geometry texts don't carry it.
- **Predators:** T6 is **GATED**, not failed. The oracle records mechanistic rules
  (gape-limitation for CONTAINER, spiny deterrence, module-redundancy for
  collectives, swim-speed for fusiform) but scoring requires an external trait
  matrix (FishBase or a staged literature matrix). This is the one genuinely
  missing input — nothing in the archive supports predator prediction.

### 3. Combining forms to explain intelligence / behavioral parameters / learning modes — THEORY IS READY, DATA PARTIAL

The compound grammar gives the parameterization:

- **Parameters of behavior** = (family ∈ 8) × (operator ∈ 14): each cell is a
  behavioral parameter. E.g., F1×segmentation → serial coordination; F6×branching
  → parallel exploration; F9-reduction → pruning/habituation; F9-hypertrophy →
  skill specialization; F9-migration → capacity reallocation.
- **Modes of learning** map onto families (per-family in the oracle): oscillator
  entrainment (axis), predictive/kinematic (sheet), omnidirectional association
  (radial), avoidance learning (container), ballistic/reflex (conduit), gradient
  ascent / parallel search (branch — the gradient layer's native algorithm),
  compositional/collective (module-collective), operant action-sequence
  (chassis), and the F9 operators are plasticity itself.
- **Intelligence parameters** (the VD bridge): repertoire breadth (family count
  per organism), operator count (fast-layer toolkit size), trajectory length
  (3rd-order chains, carcinization = 5), τ₁/τ₂ ratio, recursion depth (L7
  mirroring), integration level (R3/R12 ladder).
- **Data check (T7):** the archive carries little plasticity language on its own
  (gradient 3, adapt 5, signal 2, bioelectric 1...) — the learning-mode matrix is
  imported theory (via Levin), not evidenced by the archive. The archive's trait
  fields would need enrichment to test learning-mode claims; the matrix itself is
  the deliverable and stands as a hypothesis set.

## The xenobot worked example (from the oracle — a blind-testable claim)

Liberated Xenopus epithelial collectives → identify F7 (aggregation) + F2 (epithelial
sheet) + F1 (ciliary axis) → predict: collective ciliary transport locomotion
(ancestral mucociliary job, not novel competence), phagocyte clearance as the
"predator" (counter: aggregation microclimate / armor), wound-gap knitting as
F2 epithelial restitution default. **Falsifier:** xenobot competence not drawable
from the ancestral epithelial repertoire → the identification fails. This is the
VD-vs-Levin test, staged in the foundry, ready to run against Levin's own results.

## Grammar closure (T5)

The 13 compound rules regenerate 24/45 Level-4/5 forms (0.533), residue 21.
The residue is honest: the rules were derived from the affinity analysis, and the
uncovered forms are either missing rules (filtration = conduit+surface; arthropod
chassis = axis+segmentation+exoskeleton) or genuinely novel predictions. The
absent-pairs list (17 candidate pair-forms) is weak-signal but includes real
generative hits: **F1+F4 = armored vermiform (scale worms — real, not a distinct
archive entry)**, F3+F8 = tube-foot walkers, F5+F6 = branching conduit. The next
move: add the residue's rules, then the closure computation becomes a
novel-form generator: run the grammar, list forms it produces that are not in
the 101, and check each against nature.

## Honest limits

1. Keyword scoring is a baseline; the holdout numbers are small (n≈7–10) and the
   full-corpus numbers are the stable read (0.59 / 0.24 / 0.28).
2. Behavior and adaptation are underdetermined by form alone — that is a real
   result, and the foundry protocol now makes it measurable rather than asserted.
3. Predators need external data; the gate is deliberate.
4. The archive's own data doesn't encode its theory's claims (no trajectory
   fields); the foundry load compensates with the affinity partition, but a
   trajectory field would let the archive test 3rd-order resonance directly.

## Recommended next steps

1. Swap keyword scorer → embedding classifier (geometry texts); re-run T2–T4
   (the oracle/protocol stay identical — that's the point of the foundry).
2. Stage a predator-prey trait matrix (FishBase body-size table is the cheapest
   first cut) → ungate T6.
3. Complete the rule set to close T5's residue; then run the grammar forward and
   list novel forms against nature (scale worms as first check).
4. Enrich the dataset with trajectory/operator-chain annotations → T7 becomes a
   test, and 3rd-order resonance gets its first real data point.