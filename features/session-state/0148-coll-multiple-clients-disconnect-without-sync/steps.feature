@coll
Feature: Several aborts without Sync

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: subsequent client works
    # Multiple bad clients disconnect without completing protocol
    When we create session "bad1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "select 'BAD1'::text" to session "bad1"
    And we send Bind "" to "stmt" with params "" to session "bad1"
    And we send Execute "" to session "bad1"
    When we close session "bad1"
    When we create session "bad2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "select 'BAD2'::text" to session "bad2"
    And we send Bind "" to "stmt" with params "" to session "bad2"
    When we close session "bad2"
    When we create session "bad3" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "select 'BAD3'::text" to session "bad3"
    When we close session "bad3"
    # Good client should work correctly
    When we create session "good" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "clean_stmt" with query "select 999::int as val" to session "good"
    And we send Sync to session "good"
    And we send Bind "" to "clean_stmt" with params "" to session "good"
    And we send Execute "" to session "good"
    And we send Sync to session "good"
    Then session "good" should receive DataRow with "999"
