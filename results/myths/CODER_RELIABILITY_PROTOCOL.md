# Dual-Coder Reliability Protocol: Narrative Event Chains and Mytheme Coding

**Document Version:** 1.0  
**Date:** 2026-10-17  
**Status:** Standing Procedure / Approved Dual-Coder Protocol  
**Domain:** Cross-Cultural Myth and Religious Text Corpora (vi-foundry)

---

## 1. Objective and Scope

This protocol establishes the standing operational procedure for evaluating inter-coder reliability between independent human or agent coders on the grammar and event-chain layer across ancient and traditional corpora. Prior to the adoption of this protocol, the grammar/event-chain layer operated under single-coder (agent-coded) conditions.

This procedure applies to all narrative corpora (Egyptian, Near Eastern, Siberian, Australian, Austronesian/Formosan, and Diachronic Biblical corpora).

---

## 2. Sampling Frame

Every reliability evaluation uses a stratified pilot sample of **$N = 12$ entries**, drawing two representative texts across six cultural/generic traditions:
1. **Egyptian Myth** (2 entries: Old Kingdom / New Kingdom narrative myths)
2. **Egyptian Religion** (2 entries: Solar hymns / ritual prayers)
3. **Hebrew Psalms** (2 entries: Wisdom/Law and Royal/Cosmic psalms)
4. **Siberian / Koryak** (2 entries: Bogoras/Jochelson oral narrative texts)
5. **Australian Aboriginal** (2 entries: Parker 1896 legend corpus)
6. **Formosan Indigenous** (2 entries: Brill primary anthropogonic myths)

If a specified raw text is physically missing or damaged, an explicit replacement entry from the exact same tradition must be substituted, logged, and justified in the pilot attestation.

---

## 3. Coder Blinding and Independence

1. **Strict Blinding:** Coder B must code completely blind to existing Coder A codings, consensus databases, and prior feature tables.
2. **Raw Text Source Requirement:** All coding must proceed strictly from primary raw source texts (unannotated English translations / corpus text files) located in `vi-foundry/data` or authoritative source repositories.
3. **Training & Schemas:** Coders may consult global codebooks (`NEC_RUBRIC.md`, `NEC_V1_1_RUBRIC.md`) and structural schema templates (e.g. 3–4 reference examples for output field structure and controlled vocabulary), but must never inspect the counterpart codings for target test texts.
4. **Attestation:** Every completed recode file must contain explicit `"coder": "B"` and `"blind": true` attributes, accompanied by a timestamped pre-attestation certifying blind extraction.

---

## 4. Controlled Coding Schema

Each record must conform to the standard NEC event-chain JSON schema:
- `id`: Canonical title / identifier of text
- `corpus`: Source corpus identifier
- `register`: Register classification (`myth` vs. `religion`)
- `origin`: Tradition provenance (`native`, `syncretic`, etc.)
- `source`: Bibliographic citation
- `data_quality`: Extraction modality (`coded_from_full_text`)
- `confidence`: Integer confidence score (1 to 4)
- `mythemes`: Unordered list of top-level structural mythemes
- `event_chain`: Ordered array of sequential narrative/ritual events:
  - `position`: 1-indexed sequential integer
  - `event_type`: Controlled event primitive tag
  - `agent`: Semantic role of initiating actor
  - `target`: Semantic role of recipient / object of action
  - `action`: Concise description of narrative action

### Controlled Vocabulary (Event Types & Mythemes)
- **Origin / Genesis:** `CREA` (creation), `ORIGIN` (etiology/naming), `EXPL` (explanation)
- **Conflict & Aggression:** `CONFL` (conflict/dispute), `COMB` (combat/fight), `VICT` (victory), `DETH` (death), `PUNS` (punishment), `TRAP` (ambush/trap)
- **Travel & Movement:** `JOUR` / `TRAVL` (journey/travel), `ESCP` (escape)
- **Social & Exchange:** `MEET` (encounter), `MARRIAGE` (nuptial union), `REQ` (request/plea), `REFU` (refusal/defiance), `REWD` (reward/investiture)
- **Authority & Ritual:** `ORDER` (command/decree), `ORDERING` (ritual sequence), `SACR` (sacrifice/offering), `WARN` (warning/prohibition), `CURS` (curse/invocation)
- **Transformation & Trickery:** `TRFM` / `TRANS` (metamorphosis), `DECP` / `DECEP` (deception), `THEF` (theft), `TEST` (challenge/ordeal), `REVR` (reversal)

---

## 5. Reliability Metrics and Thresholds

Inter-coder agreement is measured on two formal levels:

### 5.1 Event Type Agreement
1. **Aligned Cohen's Kappa ($\kappa$):** Computed at identical positions across event chains where chain lengths are equal ($L_A = L_B$).
   $$\kappa = \frac{P_o - P_e}{1 - P_e}$$
2. **Frequency-Profile Quadratic-Weighted Proxy:** When free narrative segmentation produces unequal chain lengths, aligned position kappa is undefined. Coders must report:
   - Event-type multiset Jaccard index
   - Chain length disparity ratio: $\Delta L = \frac{|L_A - L_B|}{\max(L_A, L_B)}$
   - Quadratic-weighted agreement proxy / cosine similarity on normalized event-type relative frequency profiles.
3. **Threshold Condition:** If chain-length mismatch exceeds **30%** on >50% of sampled texts, aligned kappa is formally blocked by segmentation divergence; the profile proxy must be reported alongside an explicit segmentation audit.

### 5.2 Mytheme Set Agreement
1. **Exact Jaccard Index:**
   $$J_{\text{exact}} = \frac{|M_A \cap M_B|}{|M_A \cup M_B|}$$
2. **Parent-Category Overlap Acceptance Threshold:** A mytheme pair is counted as in agreement if the tags are identical or belong to the same parent category:
   - $\text{ORIGIN} = \{\text{CREA}, \text{ORIGIN}, \text{EXPL}\}$
   - $\text{CONFLICT} = \{\text{CONFL}, \text{COMB}, \text{VICT}, \text{DETH}, \text{PUNS}, \text{TRAP}\}$
   - $\text{TRAVEL} = \{\text{JOUR}, \text{TRAVL}, \text{ESCP}\}$
   - $\text{SOCIAL} = \{\text{MEET}, \text{MARRIAGE}, \text{REQ}, \text{REFU}, \text{REWD}\}$
   - $\text{ORDER} = \{\text{ORDER}, \text{ORDERING}, \text{SACR}, \text{WARN}, \text{CURS}\}$
   - $\text{TRANSFORMATION} = \{\text{TRFM}, \text{TRANS}\}$
   - $\text{DECEPTION} = \{\text{DECP}, \text{DECEP}, \text{THEF}, \text{TEST}, \text{REVR}\}$

### 5.3 Acceptance Criteria (Pass / Fail Bar)
- **Overall Pass Bar:** Standardized reliability $\kappa \ge 0.70$ (or quadratic-weighted profile agreement $\ge 0.70$ with mean mytheme parent overlap $\ge 0.70$).
- **Per-Tradition Bar:** $\kappa \ge 0.60$ (or proxy $\ge 0.60$) for each individual tradition.
- **Mandatory Failure Action:** If either bar fails, the verdict is **REVISION-THEN-REPILOT**. The team must execute a codebook revision establishing fixed unitization/segmentation rules and unambiguous category mappings, followed by a full re-pilot before any downstream analysis may use dual-coded data.
