@session-error
Feature: Session error: Parse via Flush

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: session alive, backend PID unchanged
    Given pooler started with config from "testkit/configs/session1"
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    # Record backend PID before error
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "before_error"
    # Trigger ErrorResponse in async mode: Parse with bad SQL + Flush
    And we send Parse "" with query "bad sql syntax" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive error containing "syntax"
    # Verify the connection is still alive — same backend PID
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "after_error"
    Then named backend_pid "after_error" from session "s1" is same as "before_error"
