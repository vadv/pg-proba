@evict
Feature: No eviction (within cache)

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: executes correctly
    # Sanity check: with cache_size=2 and only 2 statements, no eviction occurs
    Given pooler started with config from "testkit/configs/cache2-size1"
    When we create session "setup" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int" to session "setup"
    And we send Bind "" to "a" with params "1" to session "setup"
    And we send Execute "" to session "setup"
    And we send Parse "b" with query "select $1::text" to session "setup"
    And we send Bind "" to "b" with params "x" to session "setup"
    And we send Execute "" to session "setup"
    And we send Sync to session "setup"
    Then session "setup" should receive DataRow with "1"
    When we close session "setup"
    And we sleep 100ms
    # Reuse both A and B — no new statement, no eviction, should work
    When we create session "test" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int" to session "test"
    And we send Bind "" to "a" with params "42" to session "test"
    And we send Execute "" to session "test"
    And we send Parse "b" with query "select $1::text" to session "test"
    And we send Bind "" to "b" with params "ok" to session "test"
    And we send Execute "" to session "test"
    And we send Sync to session "test"
    Then session "test" should receive DataRow with "42"
