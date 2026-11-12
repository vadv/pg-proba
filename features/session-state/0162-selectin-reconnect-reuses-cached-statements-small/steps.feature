@selectin
Feature: Reconnect reuses cache with small cache

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache2-size1"

  # ============================================================================
  # CORE BUG: Cache eviction during async_mode=true causes protocol desync
  # ============================================================================

  Scenario: works correctly
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    # First session: 3 sequential cycles
    And we send Parse "s1_q1" with query "select $1::int" to both
    And we send Describe "S" "s1_q1" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "s1_q1" with params "1" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Parse "s1_q2" with query "select $1::text" to both
    And we send Describe "S" "s1_q2" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "s1_q2" with params "hello" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Parse "s1_q3" with query "select $1::bigint" to both
    And we send Describe "S" "s1_q3" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "s1_q3" with params "100" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Disconnect and reconnect
    When we disconnect from both
    And we reconnect to both
    # Second session: same queries, new names
    And we send Parse "s2_q1" with query "select $1::int" to both
    And we send Describe "S" "s2_q1" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "s2_q1" with params "1" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Parse "s2_q2" with query "select $1::text" to both
    And we send Describe "S" "s2_q2" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "s2_q2" with params "hello" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Parse "s2_q3" with query "select $1::bigint" to both
    And we send Describe "S" "s2_q3" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "s2_q3" with params "100" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
  # ============================================================================
  # PYTHON INTEGRATION TEST
  # ============================================================================
