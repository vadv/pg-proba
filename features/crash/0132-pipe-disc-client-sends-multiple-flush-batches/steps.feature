@pipe-disc
Feature: Several Flush batches + RST abort

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: next client works
    When we create session "client_a" to pooler as "example_user_1" with password "" and database "example_db"
    # First batch with Flush
    And we send Parse "q1" with query "SELECT 1 as batch1" to session "client_a"
    And we send Bind "" to "q1" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Flush to session "client_a"
    # Second batch with Flush (still async)
    And we send Parse "q2" with query "SELECT generate_series(1, 3000), repeat('Y', 512)" to session "client_a"
    And we send Bind "" to "q2" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Flush to session "client_a"
    And we read 4096 bytes from session "client_a"
    When we abort TCP connection with RST for session "client_a"
    And we sleep for 2000 milliseconds
    When we create session "client_b" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "check" with query "SELECT 'MULTI_FLUSH_CLEAN'::text as status" to session "client_b"
    And we send Sync to session "client_b"
    And we send Bind "" to "check" with params "" to session "client_b"
    And we send Execute "" to session "client_b"
    And we send Sync to session "client_b"
    Then session "client_b" should receive DataRow with "MULTI_FLUSH_CLEAN"
