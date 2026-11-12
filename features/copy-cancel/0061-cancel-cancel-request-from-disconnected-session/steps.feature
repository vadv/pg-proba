@cancel
Feature: Cancel: request from disconnected session

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: other session unharmed
    # Create main session and store backend_pid/secret_key
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Execute a simple query to ensure connection is working
    And we send SimpleQuery "SELECT 1" to session "main"
    # Abruptly disconnect main session (simulates network failure)
    And we abort TCP connection for session "main"
    # Wait a bit for the connection to be returned to pool
    And we sleep 500ms
    # Create second session - it may get the same backend connection from pool
    And we create session "second" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Start a long-running query on second session
    And we send SimpleQuery "SELECT pg_sleep(2)" to session "second" without waiting
    # Wait a bit to ensure the query has started
    And we sleep 200ms
    # Send cancel request using main session's old backend_pid/secret_key
    # This should NOT cancel the second session's query because secret_key should be different
    And we send cancel request for session "main"
    # Wait for the pg_sleep to complete (3 seconds total to be safe)
    And we sleep 3000ms
    # Verify that second session completed without error (was not cancelled)
    Then session "second" should complete without error
