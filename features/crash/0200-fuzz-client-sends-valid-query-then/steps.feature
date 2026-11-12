@fuzz
Feature: Valid query then abrupt disconnect

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/plain1"

  # ===========================================================================
  # Broken Headers Tests - fuzz first, then verify new client works
  # ===========================================================================

  Scenario: pooler alive, next client works
    # Client sends valid query, receives response, then abruptly disconnects
    When we create session "mixed" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q1" with query "SELECT 1" to session "mixed"
    And we send Sync to session "mixed"
    And we send Bind "" to "q1" with params "" to session "mixed"
    And we send Execute "" to session "mixed"
    And we send Sync to session "mixed"
    Then session "mixed" should receive DataRow with "1"
    # Now client abruptly disconnects
    When we close session "mixed"
    # New client should work fine
    And we create session "valid" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q" with query "SELECT 'MIXED_OK'" to session "valid"
    And we send Sync to session "valid"
    And we send Bind "" to "q" with params "" to session "valid"
    And we send Execute "" to session "valid"
    And we send Sync to session "valid"
    Then session "valid" should receive DataRow with "MIXED_OK"
    And pooler should still be running
