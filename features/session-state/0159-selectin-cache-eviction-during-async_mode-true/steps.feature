@selectin
Feature: Cache eviction under async_mode=true

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
    # 1st Parse+Describe+Flush: fills cache slot 1, sets async_mode=true
    And we send Parse "stmt1" with query "select $1::int" to both
    And we send Describe "S" "stmt1" to both
    And we send Flush to both
    And we verify partial response received from both
    # async_mode=true, expected_responses=0, server NOT released (async prevents it)
    # 2nd Parse+Describe+Flush: fills cache slot 2, still async_mode=true
    And we send Parse "stmt2" with query "select $1::text" to both
    And we send Describe "S" "stmt2" to both
    And we send Flush to both
    And we verify partial response received from both
    # 3rd Parse: cache is full (size=2), EVICTS oldest entry!
    # register_prepared_statement sends Close+Sync but recv fails (async_mode=true, expected=0)
    # CloseComplete+ReadyForQuery left in TCP buffer → PROTOCOL DESYNC
    And we send Parse "stmt3" with query "select $1::bigint" to both
    And we send Describe "S" "stmt3" to both
    And we send Flush to both
    And we verify partial response received from both
    # Now execute all three
    And we send Bind "" to "stmt1" with params "1" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Bind "" to "stmt2" with params "hello" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    When we send Bind "" to "stmt3" with params "100" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
