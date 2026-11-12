@lang-go
Feature: Go lib/pq: single statement

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: single prepared statement through pooler
    When I run shell command:
      """
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db?sslmode=disable"
      cd testkit/drivers/go && go test -v -run TestLibPQOnePrepared ./prepared
      """
    Then the command should succeed
    And the command output should contain "PASS: TestLibPQOnePrepared"
