@lang-go
Feature: Go: stop race

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: stop race does not crash pooler
    When I run shell command:
      """
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db?sslmode=disable"
      export PG_PORT="${PG_PORT}"
      cd testkit/drivers/go && go test -v -run Test_RaceStop ./extended
      """
    Then the command should succeed
    And the command output should contain "PASS: Test_RaceStop"
