@psne
Feature: Several stale Parses from one client

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: next client gets all own data
    Given pooler started with config from "testkit/configs/cache100-size1"
    # Client sends multiple Parse messages for different queries, then disconnects.
    # All of them end up in the server cache but none reach PostgreSQL.
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "add" with query "select $1::int + $2::int" to session "one"
    And we send Parse "mul" with query "select $1::int * $2::int" to session "one"
    And we send Parse "sub" with query "select $1::int - $2::int" to session "one"
    And we close session "one"
    And we sleep 200ms
    # Next client uses all three queries — each must work
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "add" with query "select $1::int + $2::int" to session "two"
    And we send Bind "" to "add" with params "10, 5" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "15"
    And we send Parse "mul" with query "select $1::int * $2::int" to session "two"
    And we send Bind "" to "mul" with params "10, 5" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "50"
    And we send Parse "sub" with query "select $1::int - $2::int" to session "two"
    And we send Bind "" to "sub" with params "10, 5" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "5"
