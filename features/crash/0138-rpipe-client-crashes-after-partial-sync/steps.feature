@rpipe
Feature: Abort after partial Sync

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: next client recovers
    # Client sends some commands, Sync, more commands, then crashes
    When we create session "partial" to pooler as "example_user_1" with password "" and database "example_db"
    # First batch with Sync
    And we send Parse "first" with query "SELECT 'FIRST'::text" to session "partial"
    And we send Bind "" to "first" with params "" to session "partial"
    And we send Execute "" to session "partial"
    And we send Sync to session "partial"
    # Second batch without Sync - client crashes here
    And we send Parse "second" with query "SELECT generate_series(1, 500)" to session "partial"
    And we send Bind "" to "second" with params "" to session "partial"
    And we send Execute "" to session "partial"
    # No Sync - crash!
    When we close session "partial"
    # Next client should get clean state
    When we create session "next" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "check" with query "SELECT 'RECOVERED'::text as status" to session "next"
    And we send Sync to session "next"
    And we send Bind "" to "check" with params "" to session "next"
    And we send Execute "" to session "next"
    And we send Sync to session "next"
    Then session "next" should receive DataRow with "RECOVERED"
