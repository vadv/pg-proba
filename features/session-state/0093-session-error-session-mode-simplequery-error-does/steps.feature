@session-error
Feature: Session error: SimpleQuery error

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
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "before"
    # SimpleQuery uses simple protocol — async_mode is never set, so mark_bad is never called
    # regardless of pool mode. This is a baseline regression test.
    And we send SimpleQuery "SELEC not_valid" to session "s1" expecting error
    Then session "s1" should receive error containing "syntax"
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "after"
    Then named backend_pid "after" from session "s1" is same as "before"
