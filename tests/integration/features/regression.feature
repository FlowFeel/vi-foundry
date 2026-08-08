Feature: Regression Suite
  As a researcher
  I want to catch regressions in my analysis
  So that changes to code don't silently change results

  Scenario: Baseline oracle comparison
    Given the simulacrum stack is converged
    When I run the full §12 pipeline
    Then all results should match baseline/oracle.yml within tolerance 0.001
    And any known divergences should be documented

  Scenario: Numerical stability
    Given the simulacrum stack is converged
    When I run the estimation with extreme values (1e-10, 1e10)
    Then no overflow or underflow should occur
    And the estimates should be finite

  Scenario: Parallel reproducibility
    Given the simulacrum stack is converged
    When I run the simulation with 4 parallel workers
    And I run the simulation with 1 worker
    Then both runs should produce identical results
