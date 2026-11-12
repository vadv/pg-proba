@batch
Feature: Batch: anonymous Parse + Describe, overwrite

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
    And we send Parse "" with query "select $1::int" to both
    And we send Describe "S" "" to both
    And we send Parse "" with query "select $1::text, $2::text" to both
    And we send Describe "S" "" to both
    And we send Sync to both
    Then we should receive identical messages from both
  # ============================================================================
  # EDGE CASES: Describe Portal operations
  # ============================================================================
