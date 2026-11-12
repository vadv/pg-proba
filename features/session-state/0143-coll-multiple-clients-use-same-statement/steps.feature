@coll
Feature: Name collision: three clients, one name

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: each gets own result
    # Client 1 creates prepared statement "my_stmt" that returns 100
    When we create session "client1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "my_stmt" with query "select 100::int as result" to session "client1"
    And we send Sync to session "client1"
    And we send Bind "" to "my_stmt" with params "" to session "client1"
    And we send Execute "" to session "client1"
    And we send Sync to session "client1"
    Then session "client1" should receive DataRow with "100"
    # Client 2 creates prepared statement with SAME NAME "my_stmt" but DIFFERENT query that returns 200
    When we create session "client2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "my_stmt" with query "select 200::int as result" to session "client2"
    And we send Sync to session "client2"
    And we send Bind "" to "my_stmt" with params "" to session "client2"
    And we send Execute "" to session "client2"
    And we send Sync to session "client2"
    Then session "client2" should receive DataRow with "200"
    # Client 3 creates prepared statement with SAME NAME "my_stmt" but returns 300
    When we create session "client3" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "my_stmt" with query "select 300::int as result" to session "client3"
    And we send Sync to session "client3"
    And we send Bind "" to "my_stmt" with params "" to session "client3"
    And we send Execute "" to session "client3"
    And we send Sync to session "client3"
    Then session "client3" should receive DataRow with "300"
    # Now verify each client still gets their own correct result when re-executing
    When we send Bind "" to "my_stmt" with params "" to session "client1"
    And we send Execute "" to session "client1"
    And we send Sync to session "client1"
    Then session "client1" should receive DataRow with "100"
    When we send Bind "" to "my_stmt" with params "" to session "client2"
    And we send Execute "" to session "client2"
    And we send Sync to session "client2"
    Then session "client2" should receive DataRow with "200"
    When we send Bind "" to "my_stmt" with params "" to session "client3"
    And we send Execute "" to session "client3"
    And we send Sync to session "client3"
    Then session "client3" should receive DataRow with "300"
