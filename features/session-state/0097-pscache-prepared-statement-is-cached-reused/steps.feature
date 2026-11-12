@pscache
Feature: Statement cache: reuse across sessions

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: each session gets own data
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt1" with query "select $1::int + $2::int" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "stmt1" with params "10, 20" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "30"
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt1" with query "select $1::int + $2::int" to session "two"
    And we send Sync to session "two"
    And we send Bind "" to "stmt1" with params "5, 15" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "20"
