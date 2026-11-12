@fuzz
Feature: Abort after Execute without Sync

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

  Scenario: new client works
    # Client sends valid Parse+Bind+Execute but no Sync, then disconnects
    When we create session "abort3" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "SELECT generate_series(1, 100)" to session "abort3"
    And we send Bind "" to "stmt" with params "" to session "abort3"
    And we send Execute "" to session "abort3"
    And we close session "abort3"
    # New client should work fine
    And we create session "valid" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q" with query "SELECT 'ABORT_EXECUTE_OK'" to session "valid"
    And we send Sync to session "valid"
    And we send Bind "" to "q" with params "" to session "valid"
    And we send Execute "" to session "valid"
    And we send Sync to session "valid"
    Then session "valid" should receive DataRow with "ABORT_EXECUTE_OK"
    And pooler should still be running
