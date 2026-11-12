@lang-dotnet
Feature: .NET Npgsql: load

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: 16 clients x 3000 queries, cache 300
    When I run shell command:
      """
      export DATABASE_URL="Host=127.0.0.1;Port=${DOORMAN_PORT};Database=example_db;Username=example_user_1;Password=test"
      testkit/drivers/dotnet/run_test.sh batch_prepare_cache_overflow batch_prepare_cache_overflow.cs
      """
    Then the command should succeed
    And the command output should contain "batch_prepare_cache_overflow complete"
