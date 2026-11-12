@pipeline
Feature: Pipeline: cursor with partial fetches

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
    And we send Parse "" with query "SELECT * FROM generate_series(1, 100)" to both
    And we send Bind "cursor1" to "" with params "" to both
    And we send Execute "cursor1" with max_rows "10" to both
    And we send Execute "cursor1" with max_rows "10" to both
    And we send Execute "cursor1" with max_rows "10" to both
    And we send Sync to both
    Then we should receive identical messages from both
