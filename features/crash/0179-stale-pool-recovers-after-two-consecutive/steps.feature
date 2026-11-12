@stale
Feature: Two consecutive backend kills

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: pool recovers
    # Kill backend twice in a row — pool must recover both times.
    # This verifies that detection + cleanup is not a one-shot mechanism.
    Given pooler started with config from "testkit/configs/duo"
    # First kill
    When we create session "victim1" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "victim1" and store backend_pid as "pid1"
    When we send SimpleQuery "BEGIN" to session "victim1" without waiting
    Then we read SimpleQuery response from session "victim1" within 2000ms
    When we send SimpleQuery "SELECT 1" to session "victim1" without waiting
    Then we read SimpleQuery response from session "victim1" within 2000ms
    When we create session "killer" to pooler as "postgres" with password "" and database "example_db"
    When we terminate backend "pid1" from session "victim1" via session "killer"
    When we sleep for 500 milliseconds
    # Pool recovered — second client can connect and start a transaction
    When we create session "victim2" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "victim2" and store backend_pid as "pid2"
    When we send SimpleQuery "BEGIN" to session "victim2" without waiting
    Then we read SimpleQuery response from session "victim2" within 2000ms
    When we send SimpleQuery "SELECT 1" to session "victim2" without waiting
    Then we read SimpleQuery response from session "victim2" within 2000ms
    # Second kill
    When we terminate backend "pid2" from session "victim2" via session "killer"
    When we sleep for 500 milliseconds
    # Pool recovered again — third client works
    When we create session "client3" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "SELECT 3" to session "client3" without waiting
    Then we read SimpleQuery response from session "client3" within 5000ms
    Then session "client3" should receive DataRow with "3"
