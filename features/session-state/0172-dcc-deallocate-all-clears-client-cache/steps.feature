@dcc
Feature: DEALLOCATE ALL

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: cache cleared, statement re-creatable
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    # Create several prepared statements
    And we send Parse "stmt_a" with query "select $1::int + 1" to session "one"
    And we send Sync to session "one"
    And we send Parse "stmt_b" with query "select $1::int + 2" to session "one"
    And we send Sync to session "one"
    And we send Parse "stmt_c" with query "select $1::int + 3" to session "one"
    And we send Sync to session "one"
    # Execute stmt_a to verify it works
    And we send Bind "" to "stmt_a" with params "10" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "11"
    # Deallocate all
    When we send SimpleQuery "DEALLOCATE ALL" to session "one"
    # Re-create stmt_a with DIFFERENT query (same name but different logic)
    And we send Parse "stmt_a" with query "select $1::int * 100" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "stmt_a" with params "10" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    # Should get result from NEW query (1000), not old query (11)
    Then session "one" should receive DataRow with "1000"
