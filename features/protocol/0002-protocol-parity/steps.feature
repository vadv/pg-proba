@protocol-parity
Feature: Protocol parity: extended + errors

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: identical to direct PostgreSQL
    Given pooler started with config from "testkit/configs/default"
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "SELECT 1" to both
    Then we should receive identical messages from both
    When we send Parse "stmt_dance" with query "SELECT $1::int + 1" to both
    And we send Describe "S" "stmt_dance" to both
    And we send Bind "" to "stmt_dance" with params "41" to both
    And we send Describe "P" "" to both
    And we send Execute "" to both
    And we send Close "S" "stmt_dance" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send SimpleQuery "SELECT * FROM no_such_table_parity" to both
    Then we should receive identical messages from both
    When we disconnect from both
    And we reconnect to both
    And we send SimpleQuery "SELECT 2" to both
    Then we should receive identical messages from both
