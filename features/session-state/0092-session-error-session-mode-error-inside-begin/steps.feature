@session-error
Feature: Session error: error inside BEGIN

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: ROLLBACK recovers, session alive
    Given pooler started with config from "testkit/configs/session1"
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "before"
    # Open explicit transaction
    And we send SimpleQuery "BEGIN" to session "s1"
    # Trigger async error inside the transaction — puts txn into 'E' (aborted) state
    And we send Parse "" with query "SELECT 1/0" to session "s1"
    And we send Bind "" to "" with params "" to session "s1"
    And we send Execute "" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive error containing "division by zero"
    # Recover: ROLLBACK the aborted transaction
    When we send SimpleQuery "ROLLBACK" to session "s1"
    # Connection must be alive with the same backend
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "after"
    Then named backend_pid "after" from session "s1" is same as "before"
    # Verify the connection actually works — can start a new transaction
    When we send SimpleQuery "BEGIN" to session "s1"
    And we send SimpleQuery "SELECT 1" to session "s1"
    And we send SimpleQuery "COMMIT" to session "s1"
