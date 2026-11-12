@fuzz
Feature: Garbage client: negative length

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
    When fuzzer connects and sends negative length
    And we create session "valid" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q" with query "SELECT 'NEGATIVE_OK'" to session "valid"
    And we send Sync to session "valid"
    And we send Bind "" to "q" with params "" to session "valid"
    And we send Execute "" to session "valid"
    And we send Sync to session "valid"
    Then session "valid" should receive DataRow with "NEGATIVE_OK"
    And pooler should still be running
