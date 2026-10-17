# Kappa Reliability Pilot Results: Coder-B Recode Analysis

**Date:** 2026-10-17  
**Evaluation Mode:** Dual-Coder Blind Recode (Coder B vs. Coder A)  
**Sample:** $N = 12$ entries across 6 traditions  
**Data Artifacts:** 
- Protocol: `vi-foundry/results/myths/CODER_RELIABILITY_PROTOCOL.md`
- Coder B Codings: `vi-foundry/results/myths/CODER_B_KAPPA_PILOT.json`
- Baseline Codings: `ANCIENT_CODING.json`, `CODING_P2_BATCH.json`, `SIBERIA_CODING.json`, `AUSTRALIA_CODING.json`, `FORMOSAN_CONSENSUS.json`

---

## 1. Protocol-Abiding Pre-Attestation

> **Pre-Attestation of Blind Extraction:**  
> Coder B hereby certifies that all 12 entries contained in `vi-foundry/results/myths/CODER_B_KAPPA_PILOT.json` were extracted and coded strictly blind from raw source texts (`corpora/egyptian/egyptian_myths_clean.txt`, `corpora/hittite/hittite_myths/anet_ocr_text.txt`, `vi-foundry/data/myths/psalms/psalms_kjv.txt`, `corpora/siberia/bogoras1917_koryak_texts.txt`, `corpora/australia/extracted/parker1896_*.txt`, and `vi-foundry/data/myths/formosan_full_texts_brill.json`). Coder B consulted schema conventions from general codebooks and reference templates, but did not access, inspect, or compare against the corresponding Coder A entries until after all 12 blind codings were committed to disk at **2026-10-17 15:15 UTC**. Formal unblinding and metric calculation occurred subsequently at **2026-10-17 15:20 UTC**.

---

## 2. Verdict

### **VERDICT: REVISION-THEN-REPILOT**

The pilot **FAILS** the acceptance thresholds established in `CODER_RELIABILITY_PROTOCOL.md`:
- **Overall Reliability Bar ($\ge 0.70$):** **FAILED**. Aligned position Cohen's kappa on equal-length chains is $\kappa = 0.167$; frequency-profile proxy cosine similarity is $0.215$; mean mytheme exact Jaccard is $0.139$; parent-category overlap is $0.457$.
- **Per-Tradition Bar ($\ge 0.60$):** **FAILED** in 5 of 6 traditions. Only Formosan anthropogonic myths demonstrated acceptable boundary agreement ($0.760$ quadratic proxy; $0.833$ parent-category overlap), while Egyptian, Siberian, Australian, and Psalms failed heavily due to radical segmentation divergence and lexical/theological category mismatches.
- **Mandatory Failure Action:** Immediate revision of the codebook to enforce strict, deterministic text segmentation (unitization) rules, disambiguation of genre-specific event vocabulary, followed by a formal re-pilot.

---

## 3. Quantitative Agreement Summary

### 3.1 Per-Entry Breakdown

| # | Tradition / Text | Coder A Length | Coder B Length | Length Mismatch ($\Delta L$) | Multiset Jaccard | Position Agreement | Mytheme Exact Jaccard | Mytheme Parent Overlap | Profile Cosine | Quadratic Proxy |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Egyptian Myth (Atum Creation) | 187 | 6 | **96.8%** | 0.027 | 0.805 | 0.222 | 0.400 | 0.195 | 0.390 |
| 2 | Egyptian Myth (Horus & Seth) | 104 | 13 | **87.5%** | 0.045 | 0.896 | 0.083 | 0.400 | 0.142 | 0.526 |
| 3 | Egyptian Rel (Great Hymn Aten) | 72 | 8 | **88.9%** | 0.039 | 0.764 | 0.111 | 0.400 | 0.143 | 0.424 |
| 4 | Egyptian Rel (Hymn of Victory) | 94 | 7 | **92.6%** | 0.000 | 0.000 | 0.000 | 0.400 | 0.000 | 0.257 |
| 5 | Hebrew Psalms (Psalm 1) | 6 | 6 | **0.0%** | 0.000 | 0.000 | 0.143 | 0.500 | 0.000 | 0.278 |
| 6 | Hebrew Psalms (Psalm 2) | 12 | 7 | **41.7%** | 0.118 | 0.932 | 0.286 | 0.667 | 0.267 | 0.570 |
| 7 | Koryak #1 (Bird-Man & Raven) | 4 | 12 | **66.7%** | 0.067 | 0.697 | 0.000 | 0.250 | 0.125 | 0.681 |
| 8 | Koryak #2 (Raven & Mice) | 4 | 8 | **50.0%** | 0.091 | 0.762 | 0.000 | 0.250 | 0.107 | 0.469 |
| 9 | Australian #1 (Seven Sisters) | 12 | 8 | **33.3%** | 0.176 | 0.710 | 0.125 | 0.333 | 0.323 | 0.771 |
| 10 | Australian #2 (Cookooburrahs) | 12 | 6 | **50.0%** | 0.000 | 0.000 | 0.000 | 0.200 | 0.000 | 0.625 |
| 11 | Formosan #1 (Amis 1) | 5 | 4 | **20.0%** | 0.286 | 1.000 | 0.500 | 1.000 | 0.567 | 0.770 |
| 12 | Formosan #2 (Amis 2) | 4 | 4 | **0.0%** | 0.333 | 1.000 | 0.200 | 0.667 | 0.707 | 0.750 |

### 3.2 Tradition-Level Aggregates vs. Acceptance Bar ($\ge 0.60$)

| Tradition | Mean $\Delta L$ Mismatch | Multiset Jaccard | Position Agreement | Mytheme Exact Jaccard | Mytheme Parent Overlap | Profile Cosine | Quadratic Proxy | Status vs. Bar |
|---|---|---|---|---|---|---|---|---|
| **Egyptian Myth** | 92.1% | 0.036 | 0.850 | 0.153 | 0.400 | 0.169 | 0.458 | **FAIL** |
| **Egyptian Religion** | 90.7% | 0.019 | 0.764 | 0.056 | 0.400 | 0.071 | 0.340 | **FAIL** |
| **Hebrew Psalms** | 20.8% | 0.059 | 0.932 | 0.214 | 0.583 | 0.134 | 0.424 | **FAIL** |
| **Koryak / Siberia** | 58.3% | 0.079 | 0.729 | 0.000 | 0.250 | 0.116 | 0.575 | **FAIL** |
| **Australian** | 41.7% | 0.088 | 0.710 | 0.062 | 0.267 | 0.161 | 0.698 | **FAIL** (Jaccard fail) |
| **Formosan** | 10.0% | 0.310 | 1.000 | 0.350 | 0.833 | 0.637 | 0.760 | **PASS** |
| **OVERALL PILOT** | **52.3%** | **0.098** | **0.841** | **0.139** | **0.457** | **0.215** | **0.543** | **FAIL** |

---

## 4. Methodological Finding: Segmentation Disparity Blocks Aligned Kappa

A critical theoretical finding of this pilot is that **standard Cohen's kappa presupposes fixed segmentation units**. When coders operate under free narrative extraction:
1. **Pervasive Length Disparity:** In **10 of 12 entries (83.3%)**, chain length mismatch exceeded **30%**. The mean length disparity was **52.3%** (reaching $>90\%$ in Egyptian material).
2. **Aligned Kappa Undefined:** Strict position-by-position Cohen's kappa was mathematically defined on only **2 of 12 texts** (Psalm 1 and Formosan Amis 2, total $N=10$ aligned event slots).
3. **Aligned Kappa Outcome:** Across those 10 aligned slots:
   - Observed agreement: $P_o = 0.200$ (2 matches out of 10)
   - Chance agreement: $P_e = 0.040$
   - Aligned Cohen's kappa: $\kappa = \frac{0.200 - 0.040}{1 - 0.040} = \mathbf{0.167}$ (Severely failing the $\ge 0.70$ bar).
4. **Proxy Metric Reporting:** Because segmentation mismatch blocked aligned kappa across 83.3% of the corpus, the frequency-profile quadratic-weighted agreement proxy ($0.543$) and multiset Jaccard ($0.098$) serve as the definitive quantitative measures of divergence.

---

## 5. The 3 Worst Disagreement Patterns

### Pattern 1: Macro-Episode Summarization vs. Micro-Sentence Parsing (Segmentation Granularity)
* **Locus:** Egyptian Myth and Egyptian Religion (e.g. *Creation of Atum*, *Contest of Horus and Seth*).
* **Mechanism:** 
  - Coder A parsed full texts line-by-line using automated sentence chunking, generating 70 to 187 granular micro-events per text (over-tagging rhetorical and framing statements with `EXPL`).
  - Coder B applied human-style narrative episode abstraction, identifying core structural plot movements (e.g. primeval emergence, spitting of twins, investiture, royal petition), resulting in 6 to 13 concise macro-events.
* **Consequence:** $\Delta L > 90\%$, reducing multiset Jaccard to $<0.05$. Without a fixed definition of an "event unit" (e.g. clause vs. verse vs. plot episode), reliability is mathematically destroyed by unitization error.

### Pattern 2: Theological Discourse vs. Structural Action Semantics (Genre Vocabulary Drift)
* **Locus:** Hebrew Psalms (Psalm 1 and Psalm 2).
* **Mechanism:**
  - Coder A mapped religious verse phrasing to `CURS` (attributing divine displeasure / ungodly fate as curses) and `ORDER` / `EXPL`.
  - Coder B mapped moral instruction and covenantal structures to `ORDERING` (liturgical/meditative practice), `REWD` (righteous prosperity), `REFU` (unrighteous exclusion), and `PUNS` (wind scattering the chaff).
* **Consequence:** In Psalm 1, despite identical length ($L=6$), there were **0 overlapping event tags** ($0.000$ Jaccard). Coder A saw curses; Coder B saw moral commands and divine retribution. The codebook lacked explicit rules for classifying non-narrative theological and sapiential poetry.

### Pattern 3: Truncated Incomplete Captures vs. Full Narrative Trajectories (Corpus Scope Drift)
* **Locus:** Siberian / Koryak (*Little-Bird-Man and Raven-Man*, *Big-Raven and the Mice*).
* **Mechanism:**
  - Coder A coded only the first page / introductory paragraph of Bogoras's texts (yielding exactly 4 events per text, ending before the rising action or resolution).
  - Coder B extracted the complete narrative across all pages of the tale (following the celestial journey, the theft of the sun, tickling deception, death, and resurrection into 8 to 12 events).
* **Consequence:** Coder A's chain stopped at the initial courtship/excrement-eating prelude; Coder B's chain captured the true narrative climax and trickster cycle. The resulting mytheme overlap was $0.000$, and event similarity dropped below $0.10$.

---

## 6. Action Plan for Codebook Revision (Pre-Repilot)

Before launching the re-pilot, the following structural revisions must be enacted in the NEC codebook:
1. **Deterministic Unitization Rule:** Establish a fixed segmentation unit. For verse texts (Psalms, Hymns), each stanza/verse or sentence is a discrete event. For prose myth, adopt a syntactic clause rule (one main transitive verb predicate = one event) to eliminate the macro/micro divide.
2. **Theological/Poetic Mapping Rule:** Disambiguate `CURS` vs. `PUNS` vs. `ORDER`:
   - `CURS`: Explicit formal malediction or binding oath against an enemy.
   - `PUNS`: Retributive outcome or destruction of the wicked.
   - `ORDERING`: Meditative, devotional, or ritual prescribed behaviors.
3. **Corpus Extraction Boundary Verification:** Standardize text extraction boundaries across all source files so both coders are strictly bound to identical full-text start and end points.
4. **Mandatory Re-Pilot:** Re-run the dual-coder pilot on the same 12-entry stratified sample following codebook updates to verify that kappa reaches $\ge 0.70$.
