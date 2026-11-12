@cancel
Feature: Cancel: long pg_sleep query

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: cancel error received
    # Connect to pg_doorman and store backend_pid and secret_key
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Start a long-running query (pg_sleep for 10 seconds)
    And we send SimpleQuery "SELECT pg_sleep(10)" to session "main" without waiting
    # Wait a bit to ensure the query has started
    And we sleep 500ms
    # Send cancel request from a separate connection
    And we send cancel request for session "main"
    # Verify that the main session received a cancellation error
    Then session "main" should receive cancel error containing "canceling"
