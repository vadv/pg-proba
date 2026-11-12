@cancel
Feature: Cancel: arrives after query completed

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: harmless, client keeps working
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(0.1)" to session "main" without waiting
    # Wait long enough for query to complete
    And we sleep 500ms
    And we send cancel request for session "main"
    # Read the result — should be success, not cancel error
    Then session "main" should complete without error
    # Session remains usable
    When we send SimpleQuery "SELECT 1" to session "main" without waiting
    Then we read SimpleQuery response from session "main" within 2000ms
    Then session "main" should receive DataRow with "1"
