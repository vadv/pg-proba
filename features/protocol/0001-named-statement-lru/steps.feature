@named-statement-lru
Feature: LRU pressure on anonymous statements

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: named statement survives
    Given pooler started with config from "features/protocol/0001-named-statement-lru/configs"
    When we create session "one" as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt_keep" with query "SELECT 1" to session "one"
    And we send Sync to session "one"
    And we send Parse "" with query "SELECT 11" to session "one"
    And we send Sync to session "one"
    And we send Parse "" with query "SELECT 22" to session "one"
    And we send Sync to session "one"
    And we send Parse "" with query "SELECT 33" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "stmt_keep" with params "" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "1"
