@stale
Feature: Backend killed by idle_in_transaction_session_timeout

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: pool recovers
    # PostgreSQL kills backends that are idle in transaction for too long.
    # We set the timeout to 1 second and verify pg_doorman detects it.
    Given pooler started with config from "testkit/configs/duo"
    # Set a short idle_in_transaction_session_timeout via superuser
    When we create session "setup" to pooler as "postgres" with password "" and database "example_db"
    When we send SimpleQuery "ALTER SYSTEM SET idle_in_transaction_session_timeout = '1s'" to session "setup" without waiting
    Then we read SimpleQuery response from session "setup" within 2000ms
    When we send SimpleQuery "SELECT pg_reload_conf()" to session "setup" without waiting
    Then we read SimpleQuery response from session "setup" within 2000ms
    # Client opens transaction and goes idle
    When we create session "victim" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "BEGIN" to session "victim" without waiting
    Then we read SimpleQuery response from session "victim" within 2000ms
    When we send SimpleQuery "SELECT 1" to session "victim" without waiting
    Then we read SimpleQuery response from session "victim" within 2000ms
    # Wait for PostgreSQL to kill the backend (1s timeout + detection margin)
    When we sleep for 2000 milliseconds
    # Pool slot should be released — new client should succeed
    When we create session "client2" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT 2" to session "client2" without waiting
    Then we read SimpleQuery response from session "client2" within 5000ms
    Then session "client2" should receive DataRow with "2"
    # Reset the setting
    When we send SimpleQuery "ALTER SYSTEM RESET idle_in_transaction_session_timeout" to session "setup" without waiting
    Then we read SimpleQuery response from session "setup" within 2000ms
    When we send SimpleQuery "SELECT pg_reload_conf()" to session "setup" without waiting
    Then we read SimpleQuery response from session "setup" within 2000ms
