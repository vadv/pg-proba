@psne
Feature: Cache eviction during stale Parse

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: cleanup not broken
    # With cache_size=2, the third Parse triggers eviction.
    # All three are stale (no Sync). Cleanup must still work.
    Given pooler started with config from "testkit/configs/cache2-size1"
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select 1" to session "one"
    And we send Parse "b" with query "select 2" to session "one"
    And we send Parse "c" with query "select 3" to session "one"
    And we close session "one"
    And we sleep 200ms
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select 1" to session "two"
    And we send Bind "" to "a" with params "" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "1"
