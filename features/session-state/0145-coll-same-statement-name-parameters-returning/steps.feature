@coll
Feature: Name collision: parameters give different values

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: each gets own
    When we create session "sess1" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "sess2" to pooler as "example_user_1" with password "" and database "example_db"
    # sess1: my_calc multiplies by 10
    And we send Parse "my_calc" with query "select $1::int * 10 as result" to session "sess1"
    And we send Sync to session "sess1"
    # sess2: my_calc multiplies by 100
    And we send Parse "my_calc" with query "select $1::int * 100 as result" to session "sess2"
    And we send Sync to session "sess2"
    # Execute with same parameter value, expect different results
    When we send Bind "" to "my_calc" with params "5" to session "sess1"
    And we send Execute "" to session "sess1"
    And we send Sync to session "sess1"
    Then session "sess1" should receive DataRow with "50"
    When we send Bind "" to "my_calc" with params "5" to session "sess2"
    And we send Execute "" to session "sess2"
    And we send Sync to session "sess2"
    Then session "sess2" should receive DataRow with "500"
    # Execute again with different parameter
    When we send Bind "" to "my_calc" with params "7" to session "sess1"
    And we send Execute "" to session "sess1"
    And we send Sync to session "sess1"
    Then session "sess1" should receive DataRow with "70"
    When we send Bind "" to "my_calc" with params "7" to session "sess2"
    And we send Execute "" to session "sess2"
    And we send Sync to session "sess2"
    Then session "sess2" should receive DataRow with "700"
