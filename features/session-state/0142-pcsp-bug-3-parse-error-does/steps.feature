@pcsp
Feature: failed Parse must not kill the session
  Extended protocol, named statement "broken". Step 1: Parse
  "select val from nonexistent_t" -> server 42P01, client gets
  the error, session stays alive. Step 2: re-Parse same name with
  valid query (schema_a.t), Bind, Execute. Direct PG: statement
  re-registered, DataRow 1. Pooler must keep the client connection
  open across a failed Parse. Profile cache100-size1: pool_size=1.
  Upstream: pgbouncer issue #1630 (fix PR #1665 not merged).

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    And fixtures from "testkit/fixtures/fixture-search-path.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: statement alive after error
    When we create session "C" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "broken" with query "select val from nonexistent_t" to session "C"
    And we send Sync to session "C"
    Then session "C" should receive ErrorResponse with SQLSTATE "42P01"
    # re-Parse same name with a valid query — direct PG re-registers it;
    When we send Parse "broken" with query "select val from schema_a.t" to session "C"
    And we send Bind "" to "broken" with params "" to session "C"
    And we send Execute "" to session "C"
    And we send Sync to session "C"
    Then session "C" should receive DataRow with "1"
