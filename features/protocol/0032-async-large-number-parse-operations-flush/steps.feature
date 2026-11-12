@async
Feature: Flush: large number of Parse operations

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
    And we send Parse "stmt1" with query "select 1" to both
    And we send Parse "stmt2" with query "select 2" to both
    And we send Parse "stmt3" with query "select 3" to both
    And we send Parse "stmt4" with query "select 4" to both
    And we send Parse "stmt5" with query "select 5" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "stmt3" with params "" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
