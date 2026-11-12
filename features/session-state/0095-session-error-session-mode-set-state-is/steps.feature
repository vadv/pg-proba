@session-error
Feature: Session error: SET and RESET ALL after error

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: GUC not leaked to next session
    Given pooler started with config from "testkit/configs/session1-cleanup"
    # Session 1: alter session state, trigger async error, verify state persists, then close
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid
    And we send SimpleQuery "SET statement_timeout = '5s'" to session "s1"
    # Verify SET took effect
    And we send SimpleQuery "SHOW statement_timeout" to session "s1" and store response
    Then session "s1" should receive DataRow with "5s"
    # Async error — should NOT mark bad, but cleanup_state.needs_cleanup_prepare is set
    When we send Parse "" with query "bad syntax" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    # SET still active within the session after error
    When we send SimpleQuery "SHOW statement_timeout" to session "s1" and store response
    Then session "s1" should receive DataRow with "5s"
    # Close session — checkin_cleanup should run RESET ALL (because bad=false, recycle accepts)
    When we close session "s1"
    And we sleep 500ms
    # Session 2: same backend connection, but state must be clean
    When we create session "s2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s2" and store backend_pid
    # Connection reused (same PID) — proves bad=false, recycle accepted
    Then backend_pid from session "s1" should equal backend_pid from session "s2"
    # State is clean — proves RESET ALL was executed during checkin
    When we send SimpleQuery "SHOW statement_timeout" to session "s2" and store response
    Then session "s2" should receive DataRow with "0"
