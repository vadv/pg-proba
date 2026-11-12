@evict
Feature: Comparison with direct PG under eviction

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: responses identical
    # Dual-connection test: same messages sent to both raw PostgreSQL and
    # pg_doorman. Responses must be byte-identical. Proves pg_doorman's
    # prepared statement caching is transparent under eviction pressure.
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache2-size1"
    # Session 1: prepare A and B (fills server LRU to capacity)
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int" to both
    And we send Bind "" to "a" with params "1" to both
    And we send Execute "" to both
    And we send Parse "b" with query "select $1::text" to both
    And we send Bind "" to "b" with params "x" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
    # Session 2: reuse A, introduce C (triggers eviction on pg_doorman)
    When we disconnect from both
    And we reconnect to both
    And we send Parse "a" with query "select $1::int" to both
    And we send Bind "" to "a" with params "42" to both
    And we send Execute "" to both
    And we send Parse "c" with query "select $1::int + 1" to both
    And we send Bind "" to "c" with params "99" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
