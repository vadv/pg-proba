@bufclean
Feature: Client abort: inside transaction

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/plain1"

  Scenario: next client gets clean buffer
    # Start a transaction and begin large query
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "BEGIN" to session "one"
    And we send SimpleQuery "SELECT repeat('T', 1048576) as data FROM generate_series(1, 8)" to session "one" without waiting
    And we read 8192 bytes from session "one"
    And we abort TCP connection for session "one"
    And we sleep 500ms
    # New session should work correctly
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT 'TRANSACTION_CLEAN_MARKER' as marker" to session "two" and verify no stale data
    Then session "two" should have received clean response with marker "TRANSACTION_CLEAN_MARKER"
