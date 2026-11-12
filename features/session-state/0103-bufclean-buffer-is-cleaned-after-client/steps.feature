@bufclean
Feature: Client abort: during large result

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/plain1"

  Scenario: next client gets clean buffer
    # Session one: start a query that returns 8MB of text data
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    # Generate 8MB of data using repeat() - each row is about 1MB
    And we send SimpleQuery "SELECT repeat('X', 1048576) as large_data FROM generate_series(1, 8)" to session "one" without waiting
    # Read only 8KB of data (partial read)
    And we read 8192 bytes from session "one"
    # Abruptly disconnect (TCP abort)
    And we abort TCP connection for session "one"
    # Wait for pg_doorman to detect disconnect and cleanup
    And we sleep 500ms
    # Session two: connect and run a simple query
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    # Run a query that returns a known, small result
    And we send SimpleQuery "SELECT 'CLEAN_SESSION_MARKER' as marker" to session "two" and verify no stale data
    # The result should be exactly what we expect, no leftover data from session one
    Then session "two" should have received clean response with marker "CLEAN_SESSION_MARKER"
