@coll
Feature: Name collision: rapid alternation of two clients

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: odd=1, even=2, no mix-up
    When we create session "odd" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "even" to pooler as "example_user_1" with password "" and database "example_db"
    # Both use "counter" statement name but return different values
    And we send Parse "counter" with query "select 1::int as val" to session "odd"
    And we send Sync to session "odd"
    And we send Parse "counter" with query "select 2::int as val" to session "even"
    And we send Sync to session "even"
    # Rapid alternating execution
    When we send Bind "" to "counter" with params "" to session "odd"
    And we send Execute "" to session "odd"
    And we send Sync to session "odd"
    Then session "odd" should receive DataRow with "1"
    When we send Bind "" to "counter" with params "" to session "even"
    And we send Execute "" to session "even"
    And we send Sync to session "even"
    Then session "even" should receive DataRow with "2"
    When we send Bind "" to "counter" with params "" to session "odd"
    And we send Execute "" to session "odd"
    And we send Sync to session "odd"
    Then session "odd" should receive DataRow with "1"
    When we send Bind "" to "counter" with params "" to session "even"
    And we send Execute "" to session "even"
    And we send Sync to session "even"
    Then session "even" should receive DataRow with "2"
    When we send Bind "" to "counter" with params "" to session "odd"
    And we send Execute "" to session "odd"
    And we send Sync to session "odd"
    Then session "odd" should receive DataRow with "1"
    When we send Bind "" to "counter" with params "" to session "even"
    And we send Execute "" to session "even"
    And we send Sync to session "even"
    Then session "even" should receive DataRow with "2"
