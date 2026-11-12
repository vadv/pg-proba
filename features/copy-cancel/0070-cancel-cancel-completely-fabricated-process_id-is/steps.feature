@cancel
Feature: Cancel: fully fabricated process_id

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: silently ignored
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(2)" to session "main" without waiting
    And we sleep 500ms
    # Send cancel with a process_id that was never assigned
    And we send cancel request with process_id 999999 and secret_key 999999
    # The original query should NOT be cancelled
    And we sleep 3000ms
    Then session "main" should complete without error
