@bufclean
Feature: Client abort: multiple

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/plain1"

  Scenario: no data leaked
    # First disconnect
    When we create session "first" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT repeat('A', 1048576) as data FROM generate_series(1, 4)" to session "first" without waiting
    And we read 4096 bytes from session "first"
    And we abort TCP connection for session "first"
    And we sleep 300ms
    # Second disconnect
    When we create session "second" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT repeat('B', 1048576) as data FROM generate_series(1, 4)" to session "second" without waiting
    And we read 4096 bytes from session "second"
    And we abort TCP connection for session "second"
    And we sleep 300ms
    # Third disconnect
    When we create session "third" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT repeat('C', 1048576) as data FROM generate_series(1, 4)" to session "third" without waiting
    And we read 4096 bytes from session "third"
    And we abort TCP connection for session "third"
    And we sleep 300ms
    # Final session should get clean data
    When we create session "final" to pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT 'FINAL_CLEAN_MARKER' as marker" to session "final" and verify no stale data
    Then session "final" should have received clean response with marker "FINAL_CLEAN_MARKER"
