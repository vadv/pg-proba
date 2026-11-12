@msg-parity
Feature: Extended: 200 Parse/Bind/Execute before Sync

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
    And we repeat 200 times: Parse "" with query "select $1::int", Bind "" to "" with params "1", Describe "P" "", Execute "" to both
    Then we should receive identical messages from both
