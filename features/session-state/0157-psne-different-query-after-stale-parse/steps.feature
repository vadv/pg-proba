@psne
Feature: Different query after stale Parse

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: no collisions
    Given pooler started with config from "testkit/configs/cache100-size1"
    # Client 1: stale Parse for query A
    When we create session "c1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select $1::int + $2::int" to session "c1"
    And we close session "c1"
    And we sleep 200ms
    # Client 2: uses a completely different query — should not be affected
    When we create session "c2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s2" with query "select $1::text || ' hello'" to session "c2"
    And we send Bind "" to "s2" with params "world" to session "c2"
    And we send Execute "" to session "c2"
    And we send Sync to session "c2"
    Then session "c2" should receive DataRow with "world hello"
