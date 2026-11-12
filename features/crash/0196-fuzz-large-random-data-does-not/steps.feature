@fuzz
Feature: Large random packet

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

  Scenario: pooler does not crash
    When fuzzer connects and sends 10000 bytes of random data
    And we create session "valid" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q" with query "SELECT 'LARGE_RANDOM_OK'" to session "valid"
    And we send Sync to session "valid"
    And we send Bind "" to "q" with params "" to session "valid"
    And we send Execute "" to session "valid"
    And we send Sync to session "valid"
    Then session "valid" should receive DataRow with "LARGE_RANDOM_OK"
    And pooler should still be running
  # ===========================================================================
  # Connection Abort Tests - valid data then abrupt disconnect
  # ===========================================================================
