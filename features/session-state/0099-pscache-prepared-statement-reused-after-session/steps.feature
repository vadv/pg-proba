@pscache
Feature: Statement cache: reuse after session close

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: new session gets correct data
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "persistent_stmt" with query "select $1::text || ' world'" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "persistent_stmt" with params "hello" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "hello world"
    When we close session "one"
    And we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "persistent_stmt" with query "select $1::text || ' world'" to session "two"
    And we send Sync to session "two"
    And we send Bind "" to "persistent_stmt" with params "goodbye" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "goodbye world"
