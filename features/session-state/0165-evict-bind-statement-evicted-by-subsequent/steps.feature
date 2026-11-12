@evict
Feature: Bind after evicted Parse

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: executes correctly
    # Server-side LRU cache_size=2 means 3rd statement triggers eviction
    Given pooler started with config from "testkit/configs/cache2-size1"
    # Step 1: Fill server LRU to capacity with statements A and B
    When we create session "setup" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int" to session "setup"
    And we send Bind "" to "a" with params "1" to session "setup"
    And we send Execute "" to session "setup"
    And we send Sync to session "setup"
    Then session "setup" should receive DataRow with "1"
    And we send Parse "b" with query "select $1::text" to session "setup"
    And we send Bind "" to "b" with params "hello" to session "setup"
    And we send Execute "" to session "setup"
    And we send Sync to session "setup"
    Then session "setup" should receive DataRow with "hello"
    When we close session "setup"
    And we sleep 100ms
    # Step 2: New session sends batch where Parse(C) evicts A from server LRU
    # while Bind(A) is already in the client buffer.
    #
    # Parse(A) → server has A → skip (no Parse bytes in buffer)
    # Bind(A) + Execute → added to buffer, unnamed portal used then consumed
    # Parse(C) → new → register → add_to_cache(C) → eviction triggered
    # Bind(C) + Execute → added to buffer
    # Sync → flush all. Bind(A) must succeed — A must still exist on PostgreSQL.
    When we create session "test" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "a" with query "select $1::int" to session "test"
    And we send Bind "" to "a" with params "42" to session "test"
    And we send Execute "" to session "test"
    And we send Parse "c" with query "select $1::int + 1" to session "test"
    And we send Bind "" to "c" with params "99" to session "test"
    And we send Execute "" to session "test"
    And we send Sync to session "test"
    Then session "test" should receive DataRow with "42"
