@stale
Feature: Backend killed by pg_terminate_backend

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: pool releases slot, next client works
    # pool_size=1: if pg_doorman does not detect the dead server,
    # the slot stays occupied and client2 will hang forever.
    Given pooler started with config from "testkit/configs/duo"
    When we create session "victim" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "victim" and store backend_pid as "victim_pid"
    When we send SimpleQuery "BEGIN" to session "victim" without waiting
    Then we read SimpleQuery response from session "victim" within 2000ms
    When we send SimpleQuery "SELECT 1" to session "victim" without waiting
    Then we read SimpleQuery response from session "victim" within 2000ms
    # Kill the backend through a separate superuser connection
    When we create session "killer" to pooler as "postgres" with password "" and database "example_db"
    When we terminate backend "victim_pid" from session "victim" via session "killer"
    # Wait for pg_doorman to detect the dead server (>100ms threshold + margin)
    When we sleep for 500 milliseconds
    # Pool slot should be released — new client should succeed
    When we create session "client2" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT 2" to session "client2" without waiting
    Then we read SimpleQuery response from session "client2" within 5000ms
    Then session "client2" should receive DataRow with "2"
