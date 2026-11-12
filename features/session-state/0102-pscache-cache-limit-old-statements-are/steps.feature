@pscache
Feature: Statement cache: eviction at limit

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: new ones work after eviction
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt_001" with query "select 1" to session "one"
    And we send Sync to session "one"
    And we send Parse "stmt_002" with query "select 2" to session "one"
    And we send Sync to session "one"
    And we send Parse "stmt_003" with query "select 3" to session "one"
    And we send Sync to session "one"
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt_002" with query "select 2" to session "two"
    And we send Sync to session "two"
    And we send Bind "" to "stmt_002" with params "" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "2"
