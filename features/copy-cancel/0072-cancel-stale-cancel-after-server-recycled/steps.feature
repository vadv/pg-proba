@cancel
Feature: Cancel: stale after server recycled

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: new owner unharmed
    When we create session "A" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Execute and complete a query — server returns to pool
    And we send SimpleQuery "SELECT 1" to session "A"
    # Session A is idle; create session B which gets a server from pool
    And we create session "B" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    And we send SimpleQuery "SELECT pg_sleep(2)" to session "B" without waiting
    And we sleep 500ms
    # Session A tries cancel with its old credentials — mapping was removed by release()
    And we send cancel request for session "A"
    And we sleep 3000ms
    # Session B should NOT be affected
    Then session "B" should complete without error
