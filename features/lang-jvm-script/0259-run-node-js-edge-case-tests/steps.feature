@lang-nodejs
Feature: Node.js pg: edge cases

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: client edge-case scenarios
    When I run shell command:
      """
      cd testkit/drivers/nodejs && \
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db" && \
      npm install pg && \\
      node ./test_edge_cases.js
      """
    Then the command should succeed
