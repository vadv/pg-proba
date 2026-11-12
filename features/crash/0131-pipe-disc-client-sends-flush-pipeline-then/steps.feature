@pipe-disc
Feature: Flush pipeline + RST abort

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: next client works
    # Client A: pipeline with Flush (enters async mode)
    When we create session "client_a" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "q1" with query "SELECT generate_series(1, 5000) as n, repeat('X', 256) as d" to session "client_a"
    And we send Bind "" to "q1" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Flush to session "client_a"
    # Read a few bytes so pg_doorman enters roundtrip
    And we read 4096 bytes from session "client_a"
    # RST while async responses still pending
    When we abort TCP connection with RST for session "client_a"
    And we sleep for 2000 milliseconds
    # Client B: must get clean connection
    When we create session "client_b" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "check" with query "SELECT 'ASYNC_CLEAN'::text as status" to session "client_b"
    And we send Sync to session "client_b"
    And we send Bind "" to "check" with params "" to session "client_b"
    And we send Execute "" to session "client_b"
    And we send Sync to session "client_b"
    Then session "client_b" should receive DataRow with "ASYNC_CLEAN"
