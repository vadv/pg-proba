@stale
Feature: Victim client connection closed

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: after backend kill client connection closed
    # pg_doorman detects the dead server, sends ErrorResponse to the victim,
    # and closes the connection. The victim's next query should fail.
    Given pooler started with config from "testkit/configs/duo"
    When we create session "victim" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "victim" and store backend_pid as "victim_pid"
    When we send SimpleQuery "BEGIN" to session "victim" without waiting
    Then we read SimpleQuery response from session "victim" within 2000ms
    When we send SimpleQuery "SELECT 1" to session "victim" without waiting
    Then we read SimpleQuery response from session "victim" within 2000ms
    # Kill the backend
    When we create session "killer" to pooler as "postgres" with password "" and database "example_db"
    When we terminate backend "victim_pid" from session "victim" via session "killer"
    # Wait for detection
    When we sleep for 500 milliseconds
    # pg_doorman already closed the victim connection — next query must fail
    When we send SimpleQuery "SELECT 1" to session "victim" expecting connection close
