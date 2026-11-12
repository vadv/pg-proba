@batch
Feature: Batch: redefine cached with different query

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: identical to direct PostgreSQL
    # First cache stmt1 with int query
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "stmt1" with query "select $1::int" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Close and redefine with different query type
    When we send Close "S" "stmt1" to both
    And we send Parse "stmt1" with query "select $1::text" to both
    And we send Bind "" to "stmt1" with params "hello" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
  # ============================================================================
  # EDGE CASES: Session state after reconnect
  # ============================================================================
