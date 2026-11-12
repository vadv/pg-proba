@session-error
Feature: Session error: division by zero

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
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "before_error"
    # Trigger runtime error via extended protocol + Flush
    And we send Parse "" with query "SELECT 1/0" to session "s1"
    And we send Bind "" to "" with params "" to session "s1"
    And we send Execute "" to session "s1"
    And we send Flush to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive error containing "division by zero"
    When we send SimpleQuery "SELECT pg_backend_pid()" to session "s1" and store backend_pid as "after_error"
    Then named backend_pid "after_error" from session "s1" is same as "before_error"
