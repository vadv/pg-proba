@lang-go
Feature: Database aliases

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/alias"

  Scenario: connect via database alias
    When I run shell command:
      """
      export DATABASE_URL_ALIAS="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db_alias?sslmode=disable"
      cd testkit/drivers/go && go test -v -run "^TestAlias$" ./alias
      """
    Then the command should succeed
