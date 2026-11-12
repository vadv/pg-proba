@pcsp
Feature: search_path from StartupMessage

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    And fixtures from "testkit/fixtures/fixture-search-path.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  # ----------------------------------------------------------------
  # Bug 1: search_path sent in StartupMessage must reach PostgreSQL
  # before the first Parse. Otherwise unqualified table `t` resolves
  # against the role default and PostgreSQL returns 42P01.
  # ----------------------------------------------------------------
  Scenario: reaches backend
    When we create session "A" to pooler as "example_user_1" with password "" and database "example_db" and startup parameters "search_path=schema_a"
    And we send Parse "lookup" with query "select val from t" to session "A"
    And we send Sync to session "A"
    And we send Bind "" to "lookup" with params "" to session "A"
    And we send Execute "" to session "A"
    And we send Sync to session "A"
    Then session "A" should receive DataRow with "1"
  # ----------------------------------------------------------------
  # Bug 2: the prepared-cache key must include startup-time planner
  # state. The same query text under schema_a and schema_b needs two
  # server-side prepared statements, not one shared plan.
  # ----------------------------------------------------------------
