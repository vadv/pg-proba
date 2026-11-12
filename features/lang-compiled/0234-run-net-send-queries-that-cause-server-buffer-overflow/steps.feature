@lang-dotnet
Feature: .NET Npgsql: buffer overflow

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: queries overflowing server buffer
    When I run shell command:
      """
      export DATABASE_URL="Host=127.0.0.1;Port=${DOORMAN_PORT};Database=example_db;Username=example_user_1;Password=test"
      testkit/drivers/dotnet/run_test.sh anon_queries server-buffer-overflow.cs
      """
    Then the command should succeed
    And the command output should contain "server-buffer-overflow complete"
