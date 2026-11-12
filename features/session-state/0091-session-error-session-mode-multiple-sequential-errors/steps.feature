@session-error
Feature: Session error: several errors in a row

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: backend PID unchanged
    Given pooler started with config from "testkit/configs/session1"
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "original"
    # Error 1: syntax error
    And we send Parse "" with query "not valid sql" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    # Error 2: division by zero
    And we send Parse "" with query "SELECT 1/0" to session "s1"
    And we send Bind "" to "" with params "" to session "s1"
    And we send Execute "" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    # Error 3: undefined table
    And we send Parse "" with query "SELECT * FROM nonexistent_table_xyz" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    # Connection should still be alive with the same backend
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "after_errors"
    Then named backend_pid "after_errors" from session "s1" is same as "original"
