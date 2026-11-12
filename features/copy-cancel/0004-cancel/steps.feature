@cancel
Feature: Cancel: long pg_sleep query

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: cancel error received
    Given pooler started with config from "testkit/configs/default"
    When we create session "main" as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(10)" to session "main" without waiting
    And we sleep 500ms
    And we send cancel request for session "main"
    Then session "main" should receive cancel error containing "canceling"
