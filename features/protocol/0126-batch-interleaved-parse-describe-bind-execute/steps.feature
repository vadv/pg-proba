@batch
Feature: Batch: interleaved Parse/Describe/Bind/Execute with reconnects

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
    And we send Parse "s1" with query "select $1::int" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # First reconnect - interleaved operations
    When we disconnect from both
    And we reconnect to both
    And we send Parse "s1" with query "select $1::int" to both
    And we send Describe "S" "s1" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Describe "S" "s2" to both
    And we send Parse "s3" with query "select $1::bigint" to both
    And we send Describe "S" "s3" to both
    And we send Bind "p1" to "s1" with params "1" to both
    And we send Bind "p2" to "s2" with params "a" to both
    And we send Bind "p3" to "s3" with params "100" to both
    And we send Execute "p1" to both
    And we send Execute "p2" to both
    And we send Execute "p3" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Second reconnect - more interleaving
    When we disconnect from both
    And we reconnect to both
    And we send Parse "s1" with query "select $1::int" to both
    And we send Bind "p1" to "s1" with params "10" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Execute "p1" to both
    And we send Bind "p2" to "s2" with params "b" to both
    And we send Parse "s3" with query "select $1::bigint" to both
    And we send Execute "p2" to both
    And we send Bind "p3" to "s3" with params "200" to both
    And we send Execute "p3" to both
    And we send Sync to both
    Then we should receive identical messages from both
