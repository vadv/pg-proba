@pscache
Feature: Statement cache: one statement, three sessions

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: each gets own result
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "three" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "shared_stmt" with query "select $1::int * 2" to session "one"
    And we send Sync to session "one"
    And we send Parse "shared_stmt" with query "select $1::int * 2" to session "two"
    And we send Sync to session "two"
    And we send Parse "shared_stmt" with query "select $1::int * 2" to session "three"
    And we send Sync to session "three"
    When we send Bind "" to "shared_stmt" with params "1" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "shared_stmt" with params "2" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    And we send Bind "" to "shared_stmt" with params "3" to session "three"
    And we send Execute "" to session "three"
    And we send Sync to session "three"
    Then session "one" should receive DataRow with "2"
    And session "two" should receive DataRow with "4"
    And session "three" should receive DataRow with "6"
