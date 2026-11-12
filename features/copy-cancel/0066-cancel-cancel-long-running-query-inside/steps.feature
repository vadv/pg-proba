@cancel
Feature: Cancel: long query inside transaction

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: query cancelled, transaction keeps responding
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "BEGIN" to session "main"
    And we send SimpleQuery "SELECT 1" to session "main"
    # Start a long query inside the transaction
    And we send SimpleQuery "SELECT pg_sleep(10)" to session "main" without waiting
    And we sleep 500ms
    And we send cancel request for session "main"
    Then session "main" should receive cancel error containing "canceling"
    # Transaction is in aborted state — ROLLBACK should work
    When we send SimpleQuery "ROLLBACK" to session "main"
    # Session should be usable after rollback
    And we send SimpleQuery "SELECT 1" to session "main" without waiting
    Then we read SimpleQuery response from session "main" within 2000ms
    Then session "main" should receive DataRow with "1"
