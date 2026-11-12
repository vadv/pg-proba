@cancel
Feature: Cancel: correct process_id, wrong secret_key

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
    # Use session's real process_id but a fabricated secret_key
    And we send cancel request for session "main" with wrong secret_key 12345
    And we sleep 3000ms
    Then session "main" should complete without error
