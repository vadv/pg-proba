@lang-nodejs
Feature: Node.js pg: basic operations

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: simple SELECT and data queries
    When I run shell command:
      """
      cd testkit/drivers/nodejs && \
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db" && \
      npm install pg && \\
      node ./test_simple.js
      """
    Then the command should succeed
