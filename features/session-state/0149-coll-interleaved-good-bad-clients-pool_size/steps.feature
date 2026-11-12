@coll
Feature: Interleaved good and bad clients

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: good clients get own data
    # Good client 1 works normally
    When we create session "good1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "select 'GOOD1'::text as val" to session "good1"
    And we send Sync to session "good1"
    And we send Bind "" to "stmt" with params "" to session "good1"
    And we send Execute "" to session "good1"
    And we send Sync to session "good1"
    Then session "good1" should receive DataRow with "GOOD1"
    # Bad client disconnects without Sync
    When we create session "bad" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "select 'LEAKED'::text as val" to session "bad"
    And we send Bind "" to "stmt" with params "" to session "bad"
    And we send Execute "" to session "bad"
    When we close session "bad"
    # Good client 2 should work correctly and not see LEAKED data
    When we create session "good2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "select 'GOOD2'::text as val" to session "good2"
    And we send Sync to session "good2"
    And we send Bind "" to "stmt" with params "" to session "good2"
    And we send Execute "" to session "good2"
    And we send Sync to session "good2"
    Then session "good2" should receive DataRow with "GOOD2"
    # Good client 1 should still work
    When we send Bind "" to "stmt" with params "" to session "good1"
    And we send Execute "" to session "good1"
    And we send Sync to session "good1"
    Then session "good1" should receive DataRow with "GOOD1"
