@evict
Feature: Same batch against direct PostgreSQL (baseline)

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: works
    # Proves the batch pattern is valid PostgreSQL protocol.
    # If this fails, the problem is in the test, not in pg_doorman.
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    # Three statements in one batch, directly against PostgreSQL
    When we create session "pg" to postgres as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int" to session "pg"
    And we send Bind "" to "a" with params "42" to session "pg"
    And we send Execute "" to session "pg"
    And we send Parse "b" with query "select $1::text" to session "pg"
    And we send Bind "" to "b" with params "hello" to session "pg"
    And we send Execute "" to session "pg"
    And we send Parse "c" with query "select $1::int + 1" to session "pg"
    And we send Bind "" to "c" with params "99" to session "pg"
    And we send Execute "" to session "pg"
    And we send Sync to session "pg"
    Then session "pg" should receive DataRow with "42"
