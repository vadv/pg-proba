@batch
Feature: Batch: portals + reconnects

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
    # Reconnect - complex portal operations
    When we disconnect from both
    And we reconnect to both
    And we send Parse "s1" with query "select $1::int" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Parse "s3" with query "select $1::bigint" to both
    And we send Bind "portal_a" to "s1" with params "1" to both
    And we send Bind "portal_b" to "s2" with params "hello" to both
    And we send Bind "portal_c" to "s3" with params "999" to both
    And we send Describe "P" "portal_a" to both
    And we send Describe "P" "portal_b" to both
    And we send Describe "P" "portal_c" to both
    And we send Execute "portal_a" to both
    And we send Close "P" "portal_a" to both
    And we send Execute "portal_b" to both
    And we send Close "P" "portal_b" to both
    And we send Execute "portal_c" to both
    And we send Close "P" "portal_c" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Second reconnect - reuse same portal names
    When we disconnect from both
    And we reconnect to both
    And we send Parse "s1" with query "select $1::int" to both
    And we send Parse "s2" with query "select $1::text" to both
    And we send Bind "portal_a" to "s1" with params "10" to both
    And we send Bind "portal_b" to "s2" with params "world" to both
    And we send Execute "portal_a" to both
    And we send Execute "portal_b" to both
    And we send Sync to both
    Then we should receive identical messages from both
