@rpipe
Feature: Abort during pipeline batch (pool_size=1)

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: client B gets clean connection
    # Client A sends multiple Parse/Bind/Execute commands (pipeline/batch mode)
    # then disconnects WITHOUT reading all results and WITHOUT sending final Sync
    When we create session "client_a" to pooler as "example_user_1" with password "" and database "example_db"
    # Send multiple Parse commands (like batch.PrepareAsync)
    And we send Parse "batch_stmt_0" with query "SELECT 0 as batch_num, generate_series(1, 100) as num" to session "client_a"
    And we send Parse "batch_stmt_1" with query "SELECT 1 as batch_num, generate_series(1, 100) as num" to session "client_a"
    And we send Parse "batch_stmt_2" with query "SELECT 2 as batch_num, generate_series(1, 100) as num" to session "client_a"
    And we send Parse "batch_stmt_3" with query "SELECT 3 as batch_num, generate_series(1, 100) as num" to session "client_a"
    And we send Parse "batch_stmt_4" with query "SELECT 4 as batch_num, generate_series(1, 100) as num" to session "client_a"
    # Send Bind/Execute for all commands (like batch.ExecuteReaderAsync)
    And we send Bind "" to "batch_stmt_0" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Bind "" to "batch_stmt_1" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Bind "" to "batch_stmt_2" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Bind "" to "batch_stmt_3" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    And we send Bind "" to "batch_stmt_4" with params "" to session "client_a"
    And we send Execute "" to session "client_a"
    # Client A "crashes" - disconnects without sending Sync and without reading results
    # This leaves server with pending results that need to be drained
    When we close session "client_a"
    # Small delay to let pg_doorman detect the disconnect and clean up
    And we sleep for 200 milliseconds
    # Client B connects - should get clean connection, not garbage from client A
    When we create session "client_b" to pooler as "example_user_1" with password "" and database "example_db"
    # Client B executes its own query and should get correct results
    And we send Parse "my_query" with query "SELECT 'CLIENT_B_SUCCESS'::text as result" to session "client_b"
    And we send Sync to session "client_b"
    And we send Bind "" to "my_query" with params "" to session "client_b"
    And we send Execute "" to session "client_b"
    And we send Sync to session "client_b"
    Then session "client_b" should receive DataRow with "CLIENT_B_SUCCESS"
