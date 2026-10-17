# Thompson/ATU ↔ Berezkin crosswalk — report

**Date:** 2026-10-17 · **Script:** executed in-session (deterministic; no subagent, no LLM matching) · **Artifact:** `data/myths/atu_berezkin_crosswalk.json`

## Method

- Sources: `stith_thompson_index.csv` (Motif-Index, A-range: myth motifs, 5,813 unique codes) and `atu_tale_type_index_full.csv` (890 tale types) — both on disk; ATU was fully machine-readable, so the feared PDF-location gap did not materialize.
- Berezkin side: legacy `berezkin_catalogue.json` (3,494 codes with **English** titles/summaries). Note: v3's `motifs_v3.json` carries Russian titles only — English titles live in the legacy layer; any future crosswalk should re-attach English titles at parse time.
- Matcher: dual title-token containment ≥0.5 (query-side and motif-side) with plural stemming after stopword removal; runs on an inverted index; every mapping carries `match_method` and `confidence`; **no free-text LLM guessing**.

## Coverage (and what the numbers mean)

| Source | matched | total | rate |
|---|---|---|---|
| ATU tale types → ≥1 Berezkin motif | 356 | 890 | 40% |
| Thompson A-range codes → ≥1 Berezkin motif | 820 | 5,813 | 14% |
| Berezkin motifs covered by ≥1 Thompson A record | 736 | 3,494 | 21% |

**Systematic-mismatch finding (quantified, as requested):** Berezkin's catalogue is myth/etiology-dense while Thompson's A-range mixes myth motifs with thousands of saint-legend and folk-belief codes (V-, E-, G-adjacent material labeled A). ATU's 40% is higher than the "household-tale skew" hypothesis predicted — because ATU's trickster/aetiological/inanimate-world types overlap mythology substantially; the remaining 60% concentrates in novelistic tale types (K-, H-, L-ranges), which Berezkin deliberately excludes. The 21% Berezkin coverage says the two taxonomies overlay on a narrow but real mythological core; the crosswalk is a recall-oriented first pass — **use the top-confidence mappings, audit before citing**.

## Worked examples (spot-checkable in both indices)

| Thompson | label | → Berezkin |
|---|---|---|
| A21.1 | Woman who fell from the sky | M39A5A2 (1.00) |
| A21.2 | Old man from sky as creator | A19B (0.75) |
| A12 | Hermaphroditic creator | A3 (dual-creator) |
| A18.6 | Creator with sun and moon in hands | A7A, B28E |
| A50 | Conflict of good and evil creators | B1B (0.75) |

| ATU | label | → Berezkin |
|---|---|---|
| 20 | Animals eat one another up | M193A, M135A, M154A |
| 178 | The faithful animal rashly killed | M84B, K127, L71 |
| 327 | The children and the ogre | L42E |
| 200 | The dog's certificate | B117 |
| 1381 | The talkative wife and the discovered treasure | E30 |

## Caveats

1. Recall-oriented: threshold choices (0.5 containment, ≥2 shared) optimize coverage; expect false positives at the low-confidence end — sort by `confidence` and treat <0.6 as audit-required.
2. No gold-standard mapping set exists to measure precision; before publication use, hand-audit a 30-mapping sample and report the observed precision.
3. The subtended crosswalk enables: transferring Berezkin's areal data onto Thompson folklore space for folkloristics-facing audiences, and checking whether ATU-type families show the same region-affinity structure.