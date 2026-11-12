@session-error
Feature: Session error: returned to pool and reused

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: next session gets same backend
    Given pooler started with config from "testkit/configs/session1"
    # First session: get PID, trigger error, close
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid
    And we send Parse "" with query "bad sql syntax" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    And we close session "s1"
    And we sleep 500ms
    # Second session: should get the same backend connection (not destroyed)
    When we create session "s2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s2" and store backend_pid
    Then backend_pid from session "s1" should equal backend_pid from session "s2"
