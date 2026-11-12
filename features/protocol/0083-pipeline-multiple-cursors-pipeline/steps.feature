@pipeline
Feature: Pipeline: several cursors

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/messages"

  Scenario: identical to direct PostgreSQL
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt1" with query "SELECT * FROM generate_series(1, 50)" to both
    And we send Parse "stmt2" with query "SELECT * FROM generate_series(100, 150)" to both
    And we send Bind "cursor1" to "stmt1" with params "" to both
    And we send Bind "cursor2" to "stmt2" with params "" to both
    And we send Execute "cursor1" with max_rows "5" to both
    And we send Execute "cursor2" with max_rows "5" to both
    And we send Execute "cursor1" with max_rows "5" to both
    And we send Execute "cursor2" with max_rows "5" to both
    And we send Sync to both
    Then we should receive identical messages from both
