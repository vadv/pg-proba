@lang-dotnet
Feature: Npgsql multi-session: parallel prepared statements
  Eight subtests of parallel Npgsql usage: concurrent queries,
  transactions, prepared statements across 5 connections (20
  executes each), rapid connect/disconnect. Direct PG: every
  client gets its own server session, named statements never
  clash. Transaction pooler must map client statements to
  server sessions without cross-client loss.
  Profile lang40: pool_size=40, max_prepared_statements=10000.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: several sessions in parallel
    When I run shell command:
      """
      export DATABASE_URL="Host=127.0.0.1;Port=${DOORMAN_PORT};Database=example_db;Username=example_user_1;Password=test"
      testkit/drivers/dotnet/run_test.sh multi_session multi_session.cs
      """
    Then the command should succeed
    And the command output should contain "Test 1 complete"
    And the command output should contain "Test 2 complete"
    And the command output should contain "Test 3 complete"
    And the command output should contain "Test 4 complete"
    And the command output should contain "Test 5 complete"
    And the command output should contain "Test 6 complete"
    And the command output should contain "Test 7 complete"
    And the command output should contain "Test 8 complete"
    And the command output should contain "multi_session complete"
