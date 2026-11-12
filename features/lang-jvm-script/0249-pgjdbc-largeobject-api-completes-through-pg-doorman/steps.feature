@lang-java
Feature: Java pgjdbc: LargeObject fastpath

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: LO fastpath API through pooler (issue 267)
    When I run shell command:
      """
      export DATABASE_URL="jdbc:postgresql://127.0.0.1:${DOORMAN_PORT}/example_db?user=example_user_1&password=test"
      timeout 300s testkit/drivers/java/run_test.sh pgjdbc_largeobject_fastpath_issue_267 pgjdbc_largeobject_fastpath_issue_267.java
      """
    Then the command should succeed
    And the command output should contain "issue_267_pgjdbc_lob complete"
