# Claim-Strength Tiers & Coding Governance (v1)

**Date:** 2026-10-17 · **Companion to** `meta/reference/epistemics.md` (basis tiers) — this adds *method*-strength tiers for the phylomythology program. Agreed in session per Jan's directive ("Dumézil on permutation test" = pattern claims may live, but only below the findings line).

## 1. Method-strength tiers

| Tier | Requirements | House status |
|---|---|---|
| **S — publication-grade** | pre-registered falsifier + null baseline + effect survives distance/label permutation + intercoder reliability (κ ≥ 0.7) | P4-Egypt; T5; P5 (pending κ) |
| **M — evidence-in-hand** | pre-registered + nulls that pass, but underpowered/small-n or single-coder | P1, P3, T1–T4 |
| **P — pattern claims ("Dumézil class")** | no falsifier cleared yet; interpretation-shaped. Allowed ONLY as registered hypotheses; never stated as findings; each must name its future test | SKL congealing-spike story; P2 gradient reading; Laurasian storyline reading of ancient canon |
| **X — prohibited phrasing** | claims our design cannot support at any tier | "myths share origin" from content similarity; "prayer grammar is universal"; "X is Palaeolithic" from a content tree |

## 2. Data organization & labeling opportunities (adopt all)

1. **Corpus manifest**: one entry-level index (`corpus_manifest.json`) for all 2,385 event-chain chains: stable id, region_code, tradition, genre (oral-performance / literary / ritual / formula), register, coder id, codebook hash, raw-text pointer + source-file SHA, citation anchors. Required for kappa, coverage tracking, and gating analyses by genre.
2. **Genre field is not optional chrome** — the P7 negative result is probably *uniformity-of-instrument* failure: clause-level Formosan oral chains (n=354) vs ANET literary summaries (n=30) share one event_type vocabulary but not one segmentation discipline. Gate cross-tradition grammar comparisons to like-genre pairs until fixed.
3. **Codebook versioning**: event-type vocabulary is now effectively v2; freeze it, hash it into the manifest; changes require a re-coding migration note, not silent edits.
4. **Mytheme parent categories**: raw mytheme labels are observer-specific; every comparison should run on parent-category-normalized sets (already in the kappa protocol acceptance rule — extend to matrices).
5. **Provenance flags** on all literature-projected matrices (d'Huy 54×30 set the precedent) — anything not from primary text carries `projected:true` + source.

## 3. Reconsiderations (claims/coding to revisit now)

- **P2 framing**: "prayer grammar universal" → "petition/lament grammar逍遥 conservation is a *gradient* with a Near-Eastern core" — Psalms and Rig Veda are *literary* prayer, which weakens the register-universal reading; ritual-performance corpora (Ugaritic Baal) carry the separate implication the deictic data supports.
- **P4-M**: retire "monotone congealing arc"; test "congealing-by-event" (kingship-as-list) with more phase-coded texts before any claim.
- **ORDERING%**: metric is one-text-dominated; keep royal-density as primary, demote ORDERING% to annotation.
- **Deictic index**: three index variants disagree in magnitude (P3 audit) — publish only the sign-consistent result until denominators are fixed.
- **Content-layer singular narratives**: hemisphere/family effects are about *diffusion*, not *descent* — do not let the write-up drift into historical kinship from motif Jaccard.

## 4. Circumscriptions (standing commitments)

1. Every null/negative result is reported with the same prominence as positives (P2, P7 standing examples).
2. Grammar-layer claims above M-tier are frozen until κ ≥ 0.7 (pilot running).
3. Deep-time verdicts (P6) wait for the post-kappa grammar layer; content trees are supporting evidence only.
4. Any "Dumézil-class" pattern claim must name, in the same sentence, the pre-registered test that could kill it.
5. Cross-tradition grammar comparisons are genre-gated (see 2.2).