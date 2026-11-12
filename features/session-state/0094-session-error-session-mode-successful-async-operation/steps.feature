@session-error
Feature: Session error: success then failure

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: session responds after failure
    Given pooler started with config from "testkit/configs/session1"
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "before"
    # Successful async operation: Parse+Flush → ParseComplete, then Bind+Execute+Sync → results
    And we send Parse "" with query "SELECT 1" to session "s1"
    And we send Flush to session "s1"
    And we send Bind "" to "" with params "" to session "s1"
    And we send Execute "" to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive DataRow with "1"
    # Failed async operation immediately after — tests state transition from success to error
    When we send Parse "" with query "bad syntax" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive error containing "syntax"
    # Another successful async operation — tests recovery after error
    When we send Parse "" with query "SELECT 2" to session "s1"
    And we send Flush to session "s1"
    And we send Bind "" to "" with params "" to session "s1"
    And we send Execute "" to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive DataRow with "2"
    # Backend PID unchanged through all transitions
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "after"
    Then named backend_pid "after" from session "s1" is same as "before"
