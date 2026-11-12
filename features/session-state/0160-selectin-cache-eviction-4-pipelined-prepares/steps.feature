@selectin
Feature: Eviction: 4 pipelined Parses

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

  Scenario: no protocol desync
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    # Pipeline 4 Parse+Describe+Flush (cache_size=2 → 2 evictions)
    And we send Parse "p1" with query "select $1::int" to both
    And we send Describe "S" "p1" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Parse "p2" with query "select $1::text" to both
    And we send Describe "S" "p2" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Parse "p3" with query "select $1::bigint" to both
    And we send Describe "S" "p3" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Parse "p4" with query "select $1::float4" to both
    And we send Describe "S" "p4" to both
    And we send Flush to both
    And we verify partial response received from both
    # Execute all four
    And we send Bind "" to "p1" with params "1" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Bind "" to "p2" with params "hello" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Bind "" to "p3" with params "100" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Bind "" to "p4" with params "1.5" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
  # ============================================================================
  # BASIC TESTS: sequential Parse+Flush → Bind+Sync (should still work)
  # With cache_size=2, eviction happens but async_mode=false during Parse
  # ============================================================================
