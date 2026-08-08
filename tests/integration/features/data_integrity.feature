Feature: Data Integrity
  As a researcher
  I want my pipeline to handle data correctly
  So that my analysis is not corrupted by I/O issues

  Scenario: Round-trip data integrity
    Given the simulacrum stack is converged
    When I load a fixture into Postgres
    And I export it back to TSV
    Then the exported TSV should match the fixture byte-for-byte
    And no encoding issues should be present

  Scenario: Missing data handling
    Given the simulacrum stack is converged
    When I load a fixture with missing values
    Then the pipeline should correctly identify NAs
    And no silent type coercion should occur

  Scenario: Schema conformance
    Given the simulacrum stack is converged
    When I load the fixture data
    Then every column should have the declared type
    And primary key constraints should hold
