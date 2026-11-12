@cancel
Feature: Cancel: session after cancel

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: new queries work
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(10)" to session "main" without waiting
    And we sleep 500ms
    And we send cancel request for session "main"
    Then session "main" should receive cancel error containing "canceling"
    # Execute multiple queries to verify full recovery
    When we send SimpleQuery "SELECT 42" to session "main" without waiting
    Then we read SimpleQuery response from session "main" within 2000ms
    Then session "main" should receive DataRow with "42"
    When we send SimpleQuery "SELECT 'recovered'" to session "main" without waiting
    Then we read SimpleQuery response from session "main" within 2000ms
    Then session "main" should receive DataRow with "recovered"
