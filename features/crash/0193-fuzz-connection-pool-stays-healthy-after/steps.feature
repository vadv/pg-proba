@fuzz
Feature: Attack series on pool

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

  Scenario: pool alive, clients work
    When fuzzer attacks with 10 random malformed connections
    And we create session "client1" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "client2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q1" with query "SELECT 1" to session "client1"
    And we send Sync to session "client1"
    And we send Bind "" to "q1" with params "" to session "client1"
    And we send Execute "" to session "client1"
    And we send Sync to session "client1"
    Then session "client1" should receive DataRow with "1"
    And we send Parse "q2" with query "SELECT 2" to session "client2"
    And we send Sync to session "client2"
    And we send Bind "" to "q2" with params "" to session "client2"
    And we send Execute "" to session "client2"
    And we send Sync to session "client2"
    Then session "client2" should receive DataRow with "2"
    And pooler should still be running
  # ===========================================================================
  # Combined Attacks Tests
  # ===========================================================================
