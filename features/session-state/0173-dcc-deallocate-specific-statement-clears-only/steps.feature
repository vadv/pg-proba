@dcc
Feature: DEALLOCATE one statement must not kill session
  Session with named statements keep_stmt (+100) and remove_stmt
  (+200), both verified by Execute. SimpleQuery DEALLOCATE
  remove_stmt. Then keep_stmt must still Execute (105) and
  remove_stmt re-Parse as select $1::int * 10 must yield 50.
  Direct PG: DEALLOCATE silently drops one statement, session
  stays usable. Pooler must keep client connection open.
  Upstream: pgbouncer/pgbouncer#1705 — pgbouncer cleans PS maps only for
  DEALLOCATE ALL / DISCARD ALL CommandComplete tags (src/server.c).
  2026-11-12: added "no ErrorResponse" assertion. CI on odyssey
  1.7.0-rc1 (master 190db18, image bump 4855bd8): PASS — named
  DEALLOCATE no longer surfaces 26000 to the client; on the older
  image build odyssey forwarded the DEALLOCATE verbatim and the
  server answered 26000 (statement renamed server-side).
  pg_doorman replies with a synthetic CommandComplete without
  freeing the server-side statement (leak), which this test cannot
  observe from the client side.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: only it cleared
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    # Create two prepared statements
    And we send Parse "keep_stmt" with query "select $1::int + 100" to session "one"
    And we send Sync to session "one"
    And we send Parse "remove_stmt" with query "select $1::int + 200" to session "one"
    And we send Sync to session "one"
    # Verify both work
    And we send Bind "" to "keep_stmt" with params "1" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "101"
    When we send Bind "" to "remove_stmt" with params "1" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "201"
    # Deallocate only remove_stmt
    When we send SimpleQuery "DEALLOCATE remove_stmt" to session "one" and store response
    Then session "one" should not receive ErrorResponse
    # keep_stmt should still work
    And we send Bind "" to "keep_stmt" with params "5" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    Then session "one" should receive DataRow with "105"
    # Re-create remove_stmt with different query
    When we send Parse "remove_stmt" with query "select $1::int * 10" to session "one"
    And we send Sync to session "one"
    And we send Bind "" to "remove_stmt" with params "5" to session "one"
    And we send Execute "" to session "one"
    And we send Sync to session "one"
    # Should get result from NEW query (50), not old query (205)
    Then session "one" should receive DataRow with "50"
