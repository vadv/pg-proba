@selectin
Feature: Parse+Flush then Bind+Sync with small cache

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
    # Each cycle: Parse+Describe+Flush → Bind+Execute+Sync
    # Sync resets async_mode=false, so eviction during next Parse is safe
    And we send Parse "seq1" with query "select $1::int" to both
    And we send Describe "S" "seq1" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "seq1" with params "1" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Parse "seq2" with query "select $1::text" to both
    And we send Describe "S" "seq2" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "seq2" with params "hello" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Parse "seq3" with query "select $1::bigint" to both
    And we send Describe "S" "seq3" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "seq3" with params "100" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
