@lang-java
Feature: Java pgjdbc: aggressive mix
  Ten subtests of HikariCP+pgjdbc mixing batch INSERTs (val UNIQUE),
  prepared statements and transactions. test_batch_errors relies on
  ROLLBACK discarding a failed batch. Direct PG and transaction poolers
  must roll the insert back: next round reinserts val=1 into a fresh
  table without a duplicate key on test_batch_errors_val_key.
  Profile lang40: pool_size=40.
  Upstream: yandex/odyssey#1840 (after 23505 in an explicit transaction,
  Odyssey drops the statement from its server map and emits virtual
  ParseComplete on retry, so Bind fails with 26000 instead of 25P02).

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: batches + prepared + extended together
    When I run shell command:
      """
      export DATABASE_URL="jdbc:postgresql://127.0.0.1:${DOORMAN_PORT}/example_db?user=example_user_1&password=test"
      testkit/drivers/java/run_test.sh aggressive_mixed aggressive_mixed.java
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
    And the command output should contain "aggressive_mixed complete"
