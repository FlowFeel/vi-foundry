Feature: Statistical Simulation
  As a researcher
  I want my simulation to produce reproducible results
  So that my findings are credible

  Scenario: Same seed produces same output
    Given the simulacrum stack is converged
    When I run the PGLS with seed 42
    Then the output should match the baseline within tolerance 0.001
    And the output should have the same dimensions as the baseline

  Scenario: Different seeds produce different output
    Given the simulacrum stack is converged
    When I run the PGLS with seed 42
    And I run the PGLS with seed 123
    Then the outputs should differ
    And both outputs should pass validation checks

  Scenario: Convergence diagnostics pass
    Given the simulacrum stack is converged
    When I run the biphasic model with 1000 iterations
    Then the R-hat should be less than 1.01
    And the effective sample size should be greater than 400

  Scenario: Parameter recovery from synthetic data
    Given the simulacrum stack is converged
    And a synthetic population generated with known parameters
    When I run the PGLS pipeline on the synthetic data
    Then the recovered parameters should fall within the 95% CI of the true parameters
    And the null control with random parameters should NOT recover
