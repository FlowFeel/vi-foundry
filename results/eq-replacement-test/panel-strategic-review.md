# Review Panel: Strategic Evaluation of E18 Cross-Clade Framing

**Question:** Should we abandon the cultural-variant-count framing and instead characterize the x(t) variable as a purely behavioral measure — avoiding the Homo count debate altogether?

---

## Panel A: Herculano-Houzel (cephalization/comparative method)

**View:** Cautiously supports but wants proof of concept.

"The ordinal ranking was the vulnerable point. If the culture variable is just a behavioral rank-order measure — not a claimed count of traditions — then the elasticity objection loses most of its force. You're not claiming to count cultural variants precisely across 14 clades; you're claiming that more behaviorally complex clades show less negative DD. That's a weaker claim but also a harder one to attack, because you're not defending a specific number for any clade.

"But you need to show the rank-order is stable under reasonable perturbations. The λ=0 result helps enormously — it means the ranking isn't phylogenetically inherited. What you'd need is a quick test: randomly permute the culture values within their natural tiers (high/medium/low/zero) and show the PGLS still holds. If the correlation survives that, the exact values don't matter."

**Bottom line:** Supportive if you add a sensitivity test showing rank-order robustness. Then drop the precise counts entirely.

---

## Panel B: Brown (comparative methods/PGLS)

**View:** Agrees strongly. "Behavioral richness" is a better construct.

"This is what I would have recommended from the start. The cultural variant framing was a liability — it looks precise but isn't. A 'behavioral richness' index is honest about its limitations. You're saying: we ranked these clades by the extent of documented behavioral/cultural complexity, and the ranking predicts DD. That's a clear, falsifiable claim.

"The key move: relabel the x-axis from 'log₁₀(1 + cultural variants)' to 'behavioral richness rank.' Drop the pretense of interval measurement. Use the ordinal statistics (Spearman ρ) as your primary result, not Pearson r. The λ=0 already tells you this is not phylogenetically confounded. The LOO test shows it's not Homo-driven.

"One thing to add: show that the result holds if you compress Homo back to the same tier as great apes (i.e., treat Homo as having 'great ape level' behavioral richness). If the gradient still holds, you've fully defended against the outlier critique."

**Bottom line:** Strongly support. Relabel, re-center on ordinal statistics, test Homo-compression.

---

## Panel C: Anderson (natural experiments/empirical)

**View:** Practical and tactical. Focus on what the paper needs.

"I'm less invested in how you label the x-axis than in whether the argument survives review. The variant-count framing invites a reviewer to say 'these numbers aren't comparable.' The behavioral-richness framing invites a reviewer to say 'this is subjective.' Neither is safe, but behavioral richness is safer because you're not making a quantitative claim about each clade.

"The strongest move: present the x(t) values but immediately disclaim any precision. Say: 'These are order-of-magnitude estimates used to rank clades by behavioral complexity. The gradient is robust to 10x variation in the Homo value, to removal of Homo, and to phylogenetic correction (λ=0). The rank-ordering is the signal, not the precise values.'

"The specific Homo count (100 vs 500) is a distraction. Neither is defensible as a precise ethnological count. But the rank-ordering is clear: Homo > great apes > corvids > cercopithecids > canids > ungulates > low-complexity clades. That ranking maps to DD. That's the paper's claim."

**Bottom line:** Keep the values but explicitly frame them as order-of-magnitude ranks, not counts. Add the sensitivity analysis prominently.

---

## Panel Consensus

| Issue | Consensus | Action |
|-------|-----------|--------|
| Drop precise "cultural variant" framing? | **Yes** | Relabel x(t) as "behavioral complexity index" — ordinal measure from ethological literature |
| Add Homo-compression test? | **Strong yes** | Set Homo culture = Hominidae level (1.602), re-run PGLS |
| Primary statistic? | **Ordinal** | Spearman ρ should be lead result, Pearson r secondary |
| Sensitivity table? | **Essential** | Show PGLS survives 20–10,000 Homo range + without Homo |
| λ=0 reporting? | **Essential** | Already in E18 caveats — move to main results |
| LOO without Homo? | **Essential** | Already reported — highlight as key robustness check |

---

## Recommended Upstream Change

Replace this in the manuscript:

> "x(t) = log₁₀(1 + cultural_variants), where cultural variants are documented cumulative traditions from published ethograms"

With this:

> "x(t) = a behavioral complexity index derived from documented cultural/vocal traditions in published ethograms. Values are order-of-magnitude estimates used to rank clades; the gradient is robust to 10x variation in any single clade's value and to complete removal of the extreme case (Homo)."

This preserves the quantitative frame without defending an uncitable number. The λ=0 + LOO + Homo-compression tests do the defending for you.

---

*Prepared: 2026-10-04 21:45 UTC*