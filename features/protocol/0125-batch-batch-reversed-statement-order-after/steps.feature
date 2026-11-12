@batch
Feature: Batch: reversed statement order after reconnect

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
    # Cache in order: s1, s2, s3, s4, s5
    And we send Parse "s1" with query "select $1::int" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Parse "s3" with query "select $1::bigint" to both
    And we send Parse "s4" with query "select $1::float4" to both
    And we send Parse "s5" with query "select $1::float8" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Disconnect and use in reverse order
    When we disconnect from both
    And we reconnect to both
    And we send Parse "s5" with query "select $1::float8" to both
    And we send Parse "s4" with query "select $1::float4" to both
    And we send Parse "s3" with query "select $1::bigint" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Parse "s1" with query "select $1::int" to both
    And we send Describe "S" "s5" to both
    And we send Describe "S" "s4" to both
    And we send Describe "S" "s3" to both
    And we send Describe "S" "s2" to both
    And we send Describe "S" "s1" to both
    And we send Sync to both
    Then we should receive identical messages from both
