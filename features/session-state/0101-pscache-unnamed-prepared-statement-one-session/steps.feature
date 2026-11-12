@pscache
Feature: Statement cache: anonymous in one session

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: does not affect another
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "" with query "select $1::int + 100" to session "one"
    And we send Bind "" to "" with params "1" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "101"
    When we send Parse "" with query "select $1::int + 200" to session "two"
    And we send Bind "" to "" with params "1" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "201"
