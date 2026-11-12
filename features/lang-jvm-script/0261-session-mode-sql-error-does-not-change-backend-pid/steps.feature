@lang-php
Feature: PHP PDO: session mode

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/session1"

  Scenario: SQL error does not change backend PID
    When I run shell command:
      """
      export DATABASE_URL="pgsql:host=127.0.0.1;port=${DOORMAN_PORT};dbname=example_db;user=example_user_1;password=test"
      testkit/drivers/php/run_test.sh session_mode_error session_mode_error.php
      """
    Then the command should succeed
    And the command output should contain "session_mode_error complete"
