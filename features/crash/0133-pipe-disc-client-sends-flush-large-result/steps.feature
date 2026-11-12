@pipe-disc
Feature: Flush with large result + RST

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: server connection reused
    When we create session "client_a" to pooler as "example_user_1" with password "" and database "example_db"
    # Large result via Flush (async mode)
    And we send Parse "big" with query "SELECT generate_series(1, 10000) as n, repeat('Z', 512) as d" to session "client_a"
    And we send Bind "" to "big" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Flush to session "client_a"
    And we read 8192 bytes from session "client_a"
    When we abort TCP connection with RST for session "client_a"
    And we sleep for 2000 milliseconds
    # Repeat abort cycle
    When we create session "c2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "big" with query "SELECT generate_series(1, 10000) as n, repeat('W', 512) as d" to session "c2"
    And we send Bind "" to "big" with params "" to session "c2"
    And we send Execute "" to session "c2"
    And we send Flush to session "c2"
    And we read 8192 bytes from session "c2"
    When we abort TCP connection with RST for session "c2"
    And we sleep for 2000 milliseconds
    When we create session "final" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "ok" with query "SELECT 'FLUSH_SURVIVED'::text as result" to session "final"
    And we send Sync to session "final"
    And we send Bind "" to "ok" with params "" to session "final"
    And we send Execute "" to session "final"
    And we send Sync to session "final"
    Then session "final" should receive DataRow with "FLUSH_SURVIVED"
