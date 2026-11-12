@pscache
Feature: Statement cache: own statements per session

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: data not mixed
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "three" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "add_stmt" with query "select $1::int + $2::int" to session "one"
    And we send Sync to session "one"
    And we send Parse "mul_stmt" with query "select $1::int * $2::int" to session "two"
    And we send Sync to session "two"
    And we send Parse "sub_stmt" with query "select $1::int - $2::int" to session "three"
    And we send Sync to session "three"
    When we send Bind "" to "add_stmt" with params "10, 5" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "15"
    When we send Bind "" to "mul_stmt" with params "10, 5" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "50"
    When we send Bind "" to "sub_stmt" with params "10, 5" to session "three"
    And we send Execute "" to session "three"
    And we send Sync to session "three"
    Then session "three" should receive DataRow with "5"
