Feature: Simulacrum Parameter Recovery
  As a researcher
  I want to verify my pipeline recovers known parameters from synthetic data
  So that I can trust results on real data

  Scenario: Parameter recovery from synthetic population
    Given the simulacrum stack is converged
    And a synthetic population generated with lambda=0.15, theta=2.5, m0=10.0
    When I run the PGLS pipeline on the synthetic data
    Then the recovered parameters should fall within the 95% CI of the true parameters
    And the null control with random parameters should NOT recover

  Scenario: Biphasic model selection
    Given the simulacrum stack is converged
    And synthetic biphasic data with k1=0.08, k2=0.004
    When I run model selection (logistic vs exponential)
    Then the logistic model should be preferred with ΔAICc > 4
    And the exponential model should NOT be preferred

  Scenario: Cross-kingdom parameter transfer on synthetic data
    Given the simulacrum stack is converged
    And synthetic plant data with known slope 0.6
    And synthetic bird data generated from the same slope
    When I fit the plant model and apply to bird data
    Then the bird ordering should correlate with true ordering (rho > 0.7)
    And a random slope should NOT produce bird ordering (rho < 0.3)
