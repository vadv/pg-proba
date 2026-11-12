@lang-dotnet
Feature: .NET Npgsql: named + Describe

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: named statements with Describe
    When I run shell command:
      """
      export DATABASE_URL="Host=127.0.0.1;Port=${DOORMAN_PORT};Database=example_db;Username=example_user_1;Password=test"
      testkit/drivers/dotnet/run_test.sh prepared_named_describe prepared_named_describe.cs
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
    And the command output should contain "Test 9 complete"
    And the command output should contain "Test 10 complete"
    And the command output should contain "prepared_named_describe complete"
