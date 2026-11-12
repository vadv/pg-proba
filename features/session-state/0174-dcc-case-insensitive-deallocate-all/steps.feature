@dcc
Feature: DEALLOCATE ALL case-insensitive

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: cache cleared
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "my_stmt" with query "select $1::int + 1" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "my_stmt" with params "5" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "6"
    # Use lowercase deallocate all
    When we send SimpleQuery "deallocate all" to session "one"
    # Re-create with different query
    And we send Parse "my_stmt" with query "select $1::int * 2" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "my_stmt" with params "5" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "10"
