@pcsp
Feature: startup search_path must not leak to next client
  Fixture: schema_a.t=1, schema_b.t=2, public.t=3. Client 1
  connects with startup parameter search_path=schema_a, reads
  unqualified t -> 1, disconnects. Client 2 connects WITHOUT
  search_path, reads unqualified t. Direct PG: fresh session,
  role-default search_path, t -> 3 (public). Pooler must reset
  or discard the server session GUC between clients. Profile
  cache100-size1: pool_size=1 — next client lands on the same
  server. Stale comments (Bug 1/Bug 3 narrative) removed.
  Measured: odyssey resets only with the non-default
  pool_smart_discard=yes (default no); pool_discard=yes is
  forbidden when pool_reserve_prepared_statement=yes.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    And fixtures from "testkit/fixtures/fixture-search-path.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: next client has GUC reset
    When we create session "PIN" to pooler as "example_user_1" with password "" and database "example_db" and startup parameters "search_path=schema_a"
    And we send Parse "lookup_a" with query "select val from t" to session "PIN"
    And we send Sync to session "PIN"
    And we send Bind "" to "lookup_a" with params "" to session "PIN"
    And we send Execute "" to session "PIN"
    And we send Sync to session "PIN"
    Then session "PIN" should receive DataRow with "1"
    When we close session "PIN"
    And we create session "PLAIN" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "lookup_default" with query "select val from t" to session "PLAIN"
    And we send Sync to session "PLAIN"
    And we send Bind "" to "lookup_default" with params "" to session "PLAIN"
    And we send Execute "" to session "PLAIN"
    And we send Sync to session "PLAIN"
    Then session "PLAIN" should receive DataRow with "3"
    # expected: role-default search_path resolves t to public.t = 3;
