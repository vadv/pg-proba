@lang-dotnet
Feature: Npgsql: abort during 4MB streaming

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: kill socket during 4MB transfer, next client works
    When I run shell command:
      """
      export DATABASE_URL="Host=127.0.0.1;Port=${DOORMAN_PORT};Database=example_db;Username=example_user_1;Password="
      testkit/drivers/dotnet/run_test.sh pipeline_cancel_disconnect pipeline_cancel_disconnect.cs
      """
    Then the command should succeed
    And the command output should contain "Client A: Exception caught"
    And the command output should contain "Client B: Query completed successfully"
    And the command output should not contain "Bug detected"
    And the command output should contain "pipeline_cancel_disconnect complete"
