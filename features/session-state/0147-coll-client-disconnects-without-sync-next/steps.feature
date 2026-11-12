@coll
Feature: Abort without Sync (pool_size=1)

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: next client gets no garbage
    # Client 1 sends Parse/Bind/Execute but does NOT send Sync, then disconnects
    # This tests that pg_doorman properly cleans up incomplete protocol state
    # and the next client doesn't receive leftover data
    When we create session "bad_client" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "orphan_stmt" with query "select 'GARBAGE_DATA'::text as leak" to session "bad_client"
    And we send Bind "" to "orphan_stmt" with params "" to session "bad_client"
    And we send Execute "" to session "bad_client"
    # NO Sync sent - client disconnects abruptly
    When we close session "bad_client"
    # Client 2 connects and should get clean state, not garbage from previous client
    When we create session "good_client" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "my_stmt" with query "select 'CLEAN_DATA'::text as result" to session "good_client"
    And we send Sync to session "good_client"
    And we send Bind "" to "my_stmt" with params "" to session "good_client"
    And we send Execute "" to session "good_client"
    And we send Sync to session "good_client"
    Then session "good_client" should receive DataRow with "CLEAN_DATA"
