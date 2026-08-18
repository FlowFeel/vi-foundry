#!/usr/bin/env python3
"""
P8: Irreversibility Past Integration-Depth Threshold
Analysis of reintroduction survival data and Dollo's Law violations.

Tests the prediction: once an organism has relaxed toward its niche equilibrium,
reversing the process is functionally constrained. The deeper the capacity loss
(higher integration-depth threshold crossed), the lower the probability of
successful reversal.
"""

import numpy as np

# =============================================================================
# DATA: Reintroduction Survival Rates
# =============================================================================

# Data sources:
# Jule et al. 2008 (Biological Conservation 141: 355-363)
#   - 45 case studies, 17 carnivore species, 5 families
#   - Pre-2007 data
# 2023 Oxford study (Biological Conservation)
#   - ~300 large carnivore relocations, 22 countries, 2007-2021

survival_data = {
    "pre_2007": {
        "captive_born":  {"rate": 0.32, "n": 45, "source": "Jule et al. 2008"},
        "wild_caught":   {"rate": 0.52, "n": 45, "source": "Jule et al. 2008"},
    },
    "post_2007": {
        "captive_born":  {"rate": 0.64, "n": 300, "source": "Oxford 2023"},
        "wild_caught":   {"rate": 0.70, "n": 300, "source": "Oxford 2023"},
    },
}

# Steelhead trout data: Araki et al. 2007 (Science)
# 40% per generation decline in reproductive fitness
steelhead = {
    "fitness_decline_per_generation": 0.40,  # 40% per generation
    "generations_tested": 2,
    "source": "Araki et al. 2007, Science",
}

# Frankham (2008) - genetic adaptation to captivity
# Drosophila melanogaster doubled fitness in captivity in 8 generations
drosophila = {
    "fitness_doubling_generations": 8,
    "source": "Frankham 2008, Molecular Ecology",
}

# =============================================================================
# MODEL: Bi-exponential decay of survival with generations in captivity
# =============================================================================

def bi_exponential_survival(generations, a1=0.52, a2=0.32, k1=0.5, k2=0.1):
    """
    Two-component exponential decay model for reintroduction survival.

    Component 1: Rapid behavioral/physiological maladaptation (fast decay)
    Component 2: Slow genetic/evolutionary degradation (slow decay)

    S(t) = a1 * exp(-k1 * t) + a2 * exp(-k2 * t)

    Where:
    - a1 = initial survival from wild-caught baseline (52%)
    - a2 = additional survival lost to captive adaptation (difference from wild)
    - k1 = fast decay rate (behavioral, within 1-2 generations)
    - k2 = slow decay rate (genetic, over many generations)
    - t = generations in captivity

    Returns survival rate (0-1).
    """
    return a1 * np.exp(-k1 * generations) + a2 * np.exp(-k2 * generations)


def compute_decay_model():
    """Compute bi-exponential decay and identify threshold."""
    generations = np.arange(0, 20)
    survival = bi_exponential_survival(generations)

    # Find the "threshold" - generation where fast component has decayed to <10%
    # This is the integration-depth threshold after which reversal is severely constrained
    fast_component = 0.52 * np.exp(-0.5 * generations)
    threshold_gen = np.min(np.where(fast_component < 0.52 * 0.1)[0])  # 90% decay of fast component

    return generations, survival, threshold_gen


# =============================================================================
# DATA: Dollo's Law Violations - Scoring by Integration Depth
# =============================================================================

# Each claimed violation is scored by:
# 1. Integration depth (0-100): How deeply integrated was the lost trait?
#    - High: core developmental pathway, pleiotropic, essential structure
#    - Low: peripheral trait, modular, non-essential
# 2. True reversal vs. retention: Was the trait truly lost (gene deleted) or
#    merely suppressed (gene silenced but retained)?
# 3. Violation credibility (0-100): How convincing is the claim?

dollo_violations = [
    {
        "trait": "Shell coiling in gastropods (Calyptraeidae)",
        "reference": "Collin & Cipriani 2003, Proc R Soc B",
        "integration_depth": 30,  # Peripheral: coiling is a regulatory timing change
        "mechanism": "Heterochrony - larval coiling genes expressed in adults",
        "true_loss": False,  # Retained in larval stage
        "violation_credibility": 75,  # Well-supported by phylogeny
        "time_since_loss_myr": "20-100",
        "analysis": "Genes never lost - retained in larval development. Re-expression via heterochrony is not true re-evolution."
    },
    {
        "trait": "Wings in stick insects (Phasmatodea)",
        "reference": "Whiting et al. 2003, Nature",
        "integration_depth": 45,  # Moderate: wing development is complex but modular
        "mechanism": "Retention of developmental pathway, possible multiple origins",
        "true_loss": False,  # Disputed phylogeny; may have been retained
        "violation_credibility": 40,  # Phylogeny disputed; Galis (2003) critique
        "time_since_loss_myr": "~50",
        "analysis": "Phylogenetic reconstruction disputed. May reflect retention rather than re-evolution. Even if real, wings are modular structures."
    },
    {
        "trait": "Mandibular teeth in frogs (Gastrotheca guentheri)",
        "reference": "Wiens 2011, Evolution",
        "integration_depth": 55,  # Moderate-High: teeth are developmentally complex
        "mechanism": "Reactivation of tooth developmental pathway in lower jaw",
        "true_loss": False,  # Upper jaw teeth retained; lower jaw suppression
        "violation_credibility": 60,  # Plausible, but not a true reversal of gene loss
        "time_since_loss_myr": "~230",
        "analysis": "Upper jaw teeth never lost. Developmental pathway maintained for upper teeth. Re-expression in lower jaw is a regulatory change, not de novo evolution."
    },
    {
        "trait": "Ocelli in stick insects",
        "reference": "Whiting et al. 2003",
        "integration_depth": 35,  # Peripheral: simple eyes are modular
        "mechanism": "Similar to wings - pathway retention",
        "true_loss": False,  # Same phylogenetic concerns as wings
        "violation_credibility": 35,
        "time_since_loss_myr": "~50",
        "analysis": "Same phylogenetic issues as wings. Likely retention, not re-evolution."
    },
    {
        "trait": "Oviparity re-evolution in lizards",
        "reference": "Multiple studies",
        "integration_depth": 40,  # Moderate: reproductive mode is significant
        "mechanism": "Reversal of viviparity to egg-laying",
        "true_loss": True,  # Possibly true loss and re-evolution
        "violation_credibility": 50,  # Debated
        "time_since_loss_myr": "~5-10",
        "analysis": "Within the 0.5-6 Myr window for gene reactivation (Marshall et al. 1994). May be genuine retention at short timescales."
    },
    {
        "trait": "Aquatic larval stage in salamanders",
        "reference": "Multiple studies",
        "integration_depth": 50,  # Moderate: life history is integrated
        "mechanism": "Paedomorphosis reversal",
        "true_loss": False,  # Regulatory change
        "violation_credibility": 45,
        "time_since_loss_myr": "~10",
        "analysis": "Likely heterochronic shift; developmental pathways retained."
    },
    {
        "trait": "Clavicles in non-avian theropod dinosaurs",
        "reference": "Multiple studies",
        "integration_depth": 40,  # Moderate: skeletal element
        "mechanism": "Retention as vestigial structure",
        "true_loss": False,  # Never fully lost, vestigial
        "violation_credibility": 35,
        "time_since_loss_myr": "Uncertain",
        "analysis": "Clavicles were reduced but not entirely lost. Re-expression of vestigial structure."
    },
    {
        "trait": "Ancestral muscles in primates",
        "reference": "Diogo et al. (various)",
        "integration_depth": 25,  # Low: individual muscles are modular
        "mechanism": "Re-expression of ancestral muscle groups",
        "true_loss": False,  # Retained in some lineages
        "violation_credibility": 30,
        "time_since_loss_myr": "Variable",
        "analysis": "Individual muscles appearing/disappearing is common; not a deep violation."
    },
    {
        "trait": "Re-evolution of sexuality in oribatid mites",
        "reference": "Multiple studies",
        "integration_depth": 70,  # High: reproductive mode is deeply integrated
        "mechanism": "Reactivation of male-production genes",
        "true_loss": False,  # Genes retained in genome
        "violation_credibility": 55,
        "time_since_loss_myr": "~10-20",
        "analysis": "Genes for male production retained in genome. Beyond 10 Myr window for most genes (Marshall et al. 1994)."
    },
]

# =============================================================================
# ANALYSIS: Integration depth vs. violation credibility
# =============================================================================

def analyze_violations(violations):
    """Test whether deep-integration violations are rarer than peripheral ones."""
    integration_depths = np.array([v["integration_depth"] for v in violations])
    credibility = np.array([v["violation_credibility"] for v in violations])
    is_true_loss = np.array([v["true_loss"] for v in violations])

    # Correlation between integration depth and violation credibility
    corr = np.corrcoef(integration_depths, credibility)[0, 1]

    # Separate into peripheral (depth < 50) and deep (depth >= 50)
    peripheral_mask = integration_depths < 50
    deep_mask = integration_depths >= 50

    peripheral_cred = credibility[peripheral_mask]
    deep_cred = credibility[deep_mask]

    # Check if any deep-integration traits have true loss AND high credibility
    deep_true_loss = is_true_loss[deep_mask]
    deep_cred_high = deep_cred > 50
    
    # Compute deep_true_loss_and_high_cred using indices
    deep_indices = np.where(deep_mask)[0]
    deep_tl_high_cred = 0
    for i in deep_indices:
        if is_true_loss[i] and credibility[i] > 50:
            deep_tl_high_cred += 1

    return {
        "correlation_depth_credibility": float(corr),
        "peripheral_mean_credibility": float(np.mean(peripheral_cred)),
        "deep_mean_credibility": float(np.mean(deep_cred)),
        "n_peripheral": int(np.sum(peripheral_mask)),
        "n_deep": int(np.sum(deep_mask)),
        "deep_true_loss_count": int(np.sum(deep_true_loss)),
        "deep_high_credibility_count": int(np.sum(deep_cred_high)),
        "deep_true_loss_and_high_cred": deep_tl_high_cred,
    }


# =============================================================================
# EXPERIMENTAL EVOLUTION REVERSAL DATA
# =============================================================================

# Kaltenbach et al. 2015 (eLife 4:e06492)
# Directed evolution: PTE -> arylesterase -> back to PTE
# Result: Phenotypic reversal achieved, but genotypic reversal failed
# Epistasis prevented reversion to ancestral sequence
experimental_reversal = {
    "study": "Kaltenbach et al. 2015, eLife",
    "system": "Directed evolution of phosphotriesterase (PTE) to arylesterase, then back",
    "phenotypic_reversal": True,  # >10^4-fold activity restored
    "genotypic_reversal": False,   # Alternative set of mutations used
    "mechanism": "Epistasis: accumulated neutral mutations changed the fitness landscape",
    "key_finding": "Active site converged to ancestral state, but incompatible mutations elsewhere prevented full reversion",
    "implication": "Evolution is phenotypically reversible but genotypically irreversible. Deep integration (active site) constrained; peripheral (other residues) divergent.",
}

# Lenski LTEE - Citrate utilization (Cit+)
# Ara-3 population gained ability to use citrate ~31,500 generations
# Spontaneous Cit- revertants found where the duplication collapsed
citrate_reversion = {
    "study": "Lenski LTEE (multiple publications)",
    "system": "E. coli evolved in glucose-limited medium, Cit+ innovation at 31,500 gen",
    "reversion_observed": True,
    "mechanism": "Collapse of gene duplication; loss of novel function",
    "key_finding": "New function can be lost, but the ancestral genotype is not restored - the revertant has a different genetic background",
    "implication": "Even 'reversion' produces a different genotype, not a return to the ancestral state.",
}

# Bridgham et al. 2009 (PNAS) - hormone receptor evolution
# Ancestral receptor bound two hormones -> evolved to bind one -> reversion impossible
# Due to neutral mutations that destabilized the ancestral state
hormone_receptor = {
    "study": "Bridgham et al. 2009, PNAS",
    "system": "Vertebrate hormone receptor evolution",
    "reversion_possible": False,  # Could not return to ancestral state
    "mechanism": "Neutral mutations accumulated after specialization, stabilizing the new state and destabilizing the ancestral state",
    "key_finding": "The evolutionary path could not be reversed because the intermediate states had been destabilized by subsequent neutral changes",
    "implication": "Once a protein evolves away from a state, it becomes trapped - neutral drift closes off the reverse path.",
}

# =============================================================================
# SYNTHESIS
# =============================================================================

def synthesize():
    """Generate integrated analysis."""
    surv_pre = survival_data["pre_2007"]
    surv_post = survival_data["post_2007"]

    # Gap between captive-born and wild-caught
    gap_pre = surv_pre["wild_caught"]["rate"] - surv_pre["captive_born"]["rate"]
    gap_post = surv_post["wild_caught"]["rate"] - surv_post["captive_born"]["rate"]

    # Reduction in gap over time (improved techniques)
    gap_reduction = (gap_pre - gap_post) / gap_pre * 100

    # Steelhead trout: cumulative fitness after n generations
    # Fitness after n generations = (1 - 0.40)^n
    _ = [(1 - steelhead["fitness_decline_per_generation"]) ** gen for gen in range(1, 6)]

    result = f"""
P8 SYNTHESIS
============

A. REINTRODUCTION DATA
   - Pre-2007: Captive-born survival = {surv_pre['captive_born']['rate']:.0%}
              Wild-caught survival = {surv_pre['wild_caught']['rate']:.0%}
              Gap = {gap_pre:.0%}
   - Post-2007: Captive-born survival = {surv_post['captive_born']['rate']:.0%}
                Wild-caught survival = {surv_post['wild_caught']['rate']:.0%}
                Gap = {gap_post:.0%}
   - Gap reduction = {gap_reduction:.0f}% (improved techniques closing the gap)
   - Steelhead trout: {steelhead['fitness_decline_per_generation']:.0%} fitness loss PER GENERATION

B. DOLLO'S LAW VIOLATION ANALYSIS
   - Correlation between integration depth and violation credibility: {analyze_violations(dollo_violations)['correlation_depth_credibility']:.3f}
   - Peripheral traits (depth < 50): mean credibility = {analyze_violations(dollo_violations)['peripheral_mean_credibility']:.0f}
   - Deep traits (depth >= 50): mean credibility = {analyze_violations(dollo_violations)['deep_mean_credibility']:.0f}
   - Deep traits with true loss AND high credibility: {analyze_violations(dollo_violations)['deep_true_loss_and_high_cred']} of {analyze_violations(dollo_violations)['n_deep']}

C. EXPERIMENTAL EVOLUTION REVERSAL
   - Kaltenbach et al. 2015: Phenotypic reversal possible, genotypic reversal impossible
   - Bridgham et al. 2009: Hormone receptor evolution is irreversible
   - Lenski LTEE: Cit+ reversion produces different genotype, not ancestral state

D. PREDICTION: Bi-exponential decay model
   Survival(t) = 0.52*exp(-0.5*t) + 0.32*exp(-0.1*t)
   - Fast component: behavioral/physiological maladaptation (half-life ~1.4 generations)
   - Slow component: genetic/evolutionary degradation (half-life ~6.9 generations)
   - Integration-depth threshold: ~5 generations (when fast component has decayed 90%)
"""
    return result


if __name__ == "__main__":
    print(synthesize())

    # Run analysis
    analysis = analyze_violations(dollo_violations)
    print(f"\nDetailed analysis:")
    print(f"  Correlation (depth vs credibility): {analysis['correlation_depth_credibility']:.3f}")
    print(f"  Peripheral mean credibility: {analysis['peripheral_mean_credibility']:.1f}")
    print(f"  Deep mean credibility: {analysis['deep_mean_credibility']:.1f}")
    print(f"  N peripheral: {analysis['n_peripheral']}, N deep: {analysis['n_deep']}")
    print(f"  Deep true loss: {analysis['deep_true_loss_count']}")
    print(f"  Deep true loss + high credibility: {analysis['deep_true_loss_and_high_cred']}")

    # Compute decay model
    gens, surv, thresh = compute_decay_model()
    print(f"\nBi-exponential decay model:")
    print(f"  Generation 0 survival: {surv[0]:.2f}")
    print(f"  Generation 1 survival: {surv[1]:.2f}")
    print(f"  Generation 5 survival: {surv[5]:.2f}")
    print(f"  Generation 10 survival: {surv[10]:.2f}")
    print(f"  Fast component threshold (90% decay): {thresh} generations")