@cancel
Feature: Cancel: interleaved connect/disconnect/cancel

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: A cancelled, C alive
    # Create session A and start a long query
    When we create session "A" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(3)" to session "A" without waiting
    And we sleep 500ms
    # Try to cancel session A with correct credentials - this should work
    And we send cancel request for session "A"
    # Verify that session A received cancellation error
    Then session "A" should receive cancel error containing "canceling"
    # Now create session B, store credentials, then disconnect
    When we create session "B" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT 1" to session "B"
    And we abort TCP connection for session "B"
    And we sleep 100ms
    # Create session C and start a long query
    And we create session "C" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(2)" to session "C" without waiting
    And we sleep 200ms
    # Try to cancel session B (which is already disconnected) - should not affect C
    And we send cancel request for session "B"
    And we sleep 3000ms
    # Verify that session C completed without error (cancel for B did not affect C)
    Then session "C" should complete without error
