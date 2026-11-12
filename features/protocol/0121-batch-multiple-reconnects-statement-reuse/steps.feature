@batch
Feature: Batch: several reconnects with reuse

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: identical to direct PostgreSQL
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt1" with query "select $1::int" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # First reconnect
    When we disconnect from both
    And we reconnect to both
    And we send Parse "stmt1" with query "select $1::int" to both
    And we send Parse "stmt2" with query "select $1::text" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Second reconnect
    When we disconnect from both
    And we reconnect to both
    And we send Parse "stmt1" with query "select $1::int" to both
    And we send Parse "stmt2" with query "select $1::text" to both
    And we send Parse "stmt3" with query "select $1::bigint" to both
    And we send Describe "S" "stmt1" to both
    And we send Describe "S" "stmt2" to both
    And we send Describe "S" "stmt3" to both
    And we send Sync to both
    Then we should receive identical messages from both
  # ============================================================================
  # STRESS TESTS: Large batches, disconnects, terminate, uneven stmt ordering
  # ============================================================================
