@rpipe
Feature: Series of pipeline aborts

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: connection stays clean
    # Multiple clients crash during pipeline operations
    # Final client should still get clean connection
    # Client 1 crashes
    When we create session "crash1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "SELECT generate_series(1, 500) as n" to session "crash1"
    And we send Bind "" to "stmt" with params "" to session "crash1"
    And we send Execute "" to session "crash1"
    When we close session "crash1"
    # Client 2 crashes
    When we create session "crash2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt" with query "SELECT generate_series(1, 500) as n, repeat('Y', 50) as data" to session "crash2"
    And we send Bind "" to "stmt" with params "" to session "crash2"
    And we send Execute "" to session "crash2"
    And we send Sync to session "crash2"
    When we close session "crash2"
    # Client 3 crashes with multiple statements
    When we create session "crash3" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "SELECT 1" to session "crash3"
    And we send Parse "s2" with query "SELECT 2" to session "crash3"
    And we send Parse "s3" with query "SELECT 3" to session "crash3"
    And we send Bind "" to "s1" with params "" to session "crash3"
    And we send Execute "" to session "crash3"
    And we send Bind "" to "s2" with params "" to session "crash3"
    And we send Execute "" to session "crash3"
    When we close session "crash3"
    # Final client should work correctly
    When we create session "final" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "final_stmt" with query "SELECT 'ALL_CLEAN'::text as result" to session "final"
    And we send Sync to session "final"
    And we send Bind "" to "final_stmt" with params "" to session "final"
    And we send Execute "" to session "final"
    And we send Sync to session "final"
    Then session "final" should receive DataRow with "ALL_CLEAN"
