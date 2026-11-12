@lang-java
Feature: Java pgjdbc: PBDE

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: PBDE pattern through pooler
    When I run shell command:
      """
      export DATABASE_URL="jdbc:postgresql://127.0.0.1:${DOORMAN_PORT}/example_db?user=example_user_1&password=test"
      testkit/drivers/java/run_test.sh pbde pbde.java
      """
    Then the command should succeed
    And the command output should contain "pbde complete"
