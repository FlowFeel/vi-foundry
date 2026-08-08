Feature: Analysis Pipeline
  As a researcher
  I want my pipeline stages to execute in order
  So that each stage receives clean input from the previous

  Scenario: Full pipeline execution
    Given the simulacrum stack is converged
    When I execute the full §12 pipeline
    Then all stages should complete with exit code 0
    And each stage's output should be present
    And the final results should match the baseline oracle

  Scenario: Pipeline idempotency
    Given the simulacrum stack is converged
    When I execute the full pipeline twice
    Then both runs should produce identical results
    And no side effects should accumulate

  Scenario: Stage isolation
    Given the simulacrum stack is converged
    When I execute only the "pgls_fit" stage
    Then it should fail without the "load_data" stage's output
    And the error message should indicate missing dependency

  Scenario: Manifest conformance
    Given the simulacrum stack is converged
    When I execute the full pipeline
    Then every stage in pipeline.yml should have corresponding output
    And no undeclared stages should execute
