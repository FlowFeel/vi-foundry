# P9 across-datasets battery: fingerprint vs passport (2026-10-17)

Script: `scripts/myth/p9_fingerprint_passport_battery.py` · Results: `P9_FINGERPRINT_PASSPORT_ACROSS_DATASETS.json`
Method: leave-one-out nearest-class-centroid on length-normalized token profiles; macro accuracy; permutation null (shuffled labels, 500-800 draws); three feature sets: grammar (event-type profile), raw mytheme codes, parent-mytheme (18-cat mapping, judgment layer logged).

| dataset | n | k | grammar | mytheme | parent-mytheme |
|---|---|---|---|---|---|
| Ancient Near East (traditions) | 21 | 4 | **0.57, p=.006** | 0.50, p=.021 | 0.42, p=.060 |
| Hebrew vs Rig Veda (liturgical) | 27 | 2 | **0.63, p=.145** (ns) | 0.48, p=.63 | 0.44, p=.69 |
| Formosa tribes | 340 | 20 | **0.14, p=.002** | 0.12, p=.020 | 0.10, p=.090 |
| Koryak vs Amur peoples | 24 | 4 | **0.64, p=.003** | 0.42, p=.087 | 0.40, p=.116 |
| Maori: Maui-cycle vs other | 30 | 2 | 0.45, p=.63 (chance) | **0.77, p=.019** | 0.75, p=.029 |

## Findings

1. **Grammar = tradition-level fingerprint.** Wherever the label is *which tradition within a horizon*, grammar wins: ANE 0.57>0.50 (replicates the P9 pilot 0.58), Koryak-vs-Amur 0.64 vs content 0.42, Formosa 20-way 0.14>0.12 (2-3x macro-chance, significant at n=340).
2. **Content = cycle-level passport.** Wherever the label is *which story-cycle within one tradition* (Maui vs rest of Grey's Maori corpus), the pattern REVERSES: content 0.77, grammar at chance (0.45, p=.63). Narrative-cycle identity lives in motifs, not event-grammar — exactly the predicted division of labor, now observed in both directions.
3. **Hebrew-vs-RigVeda** is directionally consistent (grammar 0.63 > 0.48) but underpowered at n=27 with 800 perms (p=.145). Flag for enlargement, not a counterexample.
4. Formosa's low absolute accuracy is a base-rate effect of 20-way classification, not an instrument failure — the permutation null (≈.05 macro-chance) is what it should be compared against.

## Status
- Fingerprint/passport dissociation now observed on both sides of the predicted boundary: grammar tracks tradition-within-horizon; content tracks story-identity and geography. This upgrades P9 from single-pilot to multi-dataset pattern (still tier M: all codings are pipeline-v1; the blind-deployment kill-test remains the gate to S).
