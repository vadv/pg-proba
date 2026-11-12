@cancel
Feature: Cancel: correct backend_pid, wrong secret_key

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: cancel rejected, second session alive
    # Create first session and store backend_pid/secret_key
    When we create session "first" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Get the backend_pid from PostgreSQL
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "first" and store backend_pid
    And we send SimpleQuery "SELECT 1" to session "first"
    # Disconnect first session
    And we abort TCP connection for session "first"
    And we sleep 500ms
    # Create second session - with pool_size=1 it should get the same backend connection
    And we create session "second" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Verify we got the same backend_pid (same PostgreSQL connection from pool)
    And we send SimpleQuery "SELECT pg_backend_pid()" to session "second" and store backend_pid
    # Start a long-running query
    And we send SimpleQuery "SELECT pg_sleep(2)" to session "second" without waiting
    And we sleep 200ms
    # Send cancel using first session's credentials
    # Even if backend_pid is the same, secret_key should be different
    And we send cancel request for session "first"
    # Wait for the pg_sleep to complete
    And we sleep 3000ms
    # Verify that second session completed without error (cancel was rejected)
    Then session "second" should complete without error
