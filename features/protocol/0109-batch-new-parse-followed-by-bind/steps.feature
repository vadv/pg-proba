@batch
Feature: Batch: new Parse + Bind/Execute of cached

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: identical to direct PostgreSQL
    # First cache stmt1
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt1" with query "select $1::int" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Now batch: new Parse + Bind to cached + Execute
    When we send Parse "stmt2" with query "select $1::text" to both
    And we send Bind "" to "stmt1" with params "42" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
