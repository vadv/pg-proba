@evict
Feature: Three statements fill cache progressively

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: executes correctly
    # Variant: fill cache one-by-one across transactions, then trigger in batch
    Given pooler started with config from "testkit/configs/cache2-size1"
    # Fill server LRU: [A, B]
    When we create session "s1" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int as val" to session "s1"
    And we send Bind "" to "a" with params "10" to session "s1"
    And we send Execute "" to session "s1"
    And we send Parse "b" with query "select $1::int * 2 as val" to session "s1"
    And we send Bind "" to "b" with params "10" to session "s1"
    And we send Execute "" to session "s1"
    And we send Sync to session "s1"
    Then session "s1" should receive DataRow with "10"
    When we close session "s1"
    And we sleep 100ms
    # Reuse A, then introduce C which evicts A
    When we create session "s2" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int as val" to session "s2"
    And we send Bind "" to "a" with params "77" to session "s2"
    And we send Execute "" to session "s2"
    And we send Parse "c" with query "select $1::int - 1 as val" to session "s2"
    And we send Bind "" to "c" with params "50" to session "s2"
    And we send Execute "" to session "s2"
    And we send Sync to session "s2"
    Then session "s2" should receive DataRow with "77"
