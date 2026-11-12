@cancel
Feature: Cancel: rapid reconnect series

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: cancel kills no wrong session
    # Create first session and store backend_pid/secret_key
    When we create session "first" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT 1" to session "first"
    And we abort TCP connection for session "first"
    And we sleep 100ms
    # Create second session, disconnect it too
    And we create session "second" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT 1" to session "second"
    And we abort TCP connection for session "second"
    And we sleep 100ms
    # Create third session, disconnect it too
    And we create session "third" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT 1" to session "third"
    And we abort TCP connection for session "third"
    And we sleep 100ms
    # Now create final session that will run a long query
    And we create session "final" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(2)" to session "final" without waiting
    And we sleep 200ms
    # Try to cancel using all old session credentials - none should work
    And we send cancel request for session "first"
    And we send cancel request for session "second"
    And we send cancel request for session "third"
    # Wait for the pg_sleep to complete
    And we sleep 3000ms
    # Verify that final session completed without error
    Then session "final" should complete without error
