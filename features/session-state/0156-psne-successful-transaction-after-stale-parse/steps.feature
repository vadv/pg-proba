@psne
Feature: Successful transaction after stale Parse

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: flag cleared, data correct
    Given pooler started with config from "testkit/configs/cache100-size1"
    # Client 1: stale Parse
    When we create session "c1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select $1::int" to session "c1"
    And we close session "c1"
    And we sleep 200ms
    # Client 2: successful full transaction re-establishes the statement
    When we create session "c2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select $1::int" to session "c2"
    And we send Bind "" to "s1" with params "42" to session "c2"
    And we send Execute "" to session "c2"
    And we send Sync to session "c2"
    Then session "c2" should receive DataRow with "42"
    When we close session "c2"
    And we sleep 100ms
    # Client 3: reuses the now-valid cached statement — must work without re-parse on server
    When we create session "c3" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select $1::int" to session "c3"
    And we send Bind "" to "s1" with params "99" to session "c3"
    And we send Execute "" to session "c3"
    And we send Sync to session "c3"
    Then session "c3" should receive DataRow with "99"
