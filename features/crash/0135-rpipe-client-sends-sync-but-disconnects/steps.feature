@rpipe
Feature: Sync sent, results not fully read

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: client B gets clean state
    # Client A sends complete pipeline with Sync, but disconnects before reading all data
    When we create session "client_a" to pooler as "example_user_1" with password "" and database "example_db"
    # Send Parse/Bind/Execute for multiple large result sets
    And we send Parse "large_query" with query "SELECT generate_series(1, 1000) as num, repeat('X', 100) as data" to session "client_a"
    And we send Bind "" to "large_query" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Sync to session "client_a"
    # Client A disconnects immediately without reading the large result
    When we close session "client_a"
    And we sleep for 200 milliseconds
    # Client B should get clean connection
    When we create session "client_b" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "check_query" with query "SELECT 'CLEAN_STATE'::text as status" to session "client_b"
    And we send Sync to session "client_b"
    And we send Bind "" to "check_query" with params "" to session "client_b"
    And we send Execute "" to session "client_b"
    And we send Sync to session "client_b"
    Then session "client_b" should receive DataRow with "CLEAN_STATE"
