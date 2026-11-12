@cancel
Feature: Cancel: idle client

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: silent no-op, session keeps working
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Execute a query — in transaction mode, server returns to pool after completion
    And we send SimpleQuery "SELECT 1" to session "main"
    # Client is now idle — no server mapping exists in ClientServerMap
    And we send cancel request for session "main"
    # Cancel was silently ignored; session should remain fully functional
    And we send SimpleQuery "SELECT 42" to session "main" without waiting
    Then we read SimpleQuery response from session "main" within 2000ms
    Then session "main" should receive DataRow with "42"
