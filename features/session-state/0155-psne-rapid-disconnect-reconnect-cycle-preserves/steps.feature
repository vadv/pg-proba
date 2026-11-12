@psne
Feature: Disconnect/reconnect cycle

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: cache consistency preserved
    Given pooler started with config from "testkit/configs/cache100-size1"
    # Three rapid disconnect cycles with Parse-only, same server
    When we create session "c1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select 1" to session "c1"
    And we close session "c1"
    And we sleep 100ms
    When we create session "c2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select 1" to session "c2"
    And we close session "c2"
    And we sleep 100ms
    When we create session "c3" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select 1" to session "c3"
    And we close session "c3"
    And we sleep 100ms
    # After three stale cycles, the fourth client must still work
    When we create session "ok" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select 1" to session "ok"
    And we send Bind "" to "s1" with params "" to session "ok"
    And we send Execute "" to session "ok"
    And we send Sync to session "ok"
    Then session "ok" should receive DataRow with "1"
