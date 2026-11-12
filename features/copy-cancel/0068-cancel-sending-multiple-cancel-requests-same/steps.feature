@cancel
Feature: Cancel: several cancels for one query

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: single canceling error
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(10)" to session "main" without waiting
    And we sleep 500ms
    # Send two cancel requests rapidly
    And we send cancel request for session "main"
    And we send cancel request for session "main"
    # Should still receive exactly one cancellation error
    Then session "main" should receive cancel error containing "canceling"
