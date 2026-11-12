@copy
Feature: COPY TO STDOUT: CSV with header

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/default"

  Scenario: identical to direct PostgreSQL
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "COPY (SELECT i AS id, i*2 AS doubled, 'row_' || i AS name FROM generate_series(1, 5) AS i) TO STDOUT WITH (FORMAT CSV, HEADER)" to both
    Then we should receive identical messages from both
