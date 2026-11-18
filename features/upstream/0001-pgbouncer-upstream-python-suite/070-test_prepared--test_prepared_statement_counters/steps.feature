@upstream
@supported-pgbouncer @unsupported-odyssey @unsupported-pg_doorman
Feature: upstream test_prepared.py::test_prepared_statement_counters

  Adapted from PgBouncer 1.26.1. Native setup profile: default.
  One pytest node, a fresh PostgreSQL and a fresh pooler per scenario.
  Required extra resources: none.
  pgbouncer: supported
  odyssey: unsupported: this case requires PgBouncer SET max_prepared_statements and SHOW STATS parse counters
  pg_doorman: unsupported: this case requires PgBouncer SET max_prepared_statements and SHOW STATS parse counters

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_prepared_statement_counters
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} timeout --kill-after=5s 70s python3 -m pytest -q "test_prepared.py::test_prepared_statement_counters" -o asyncio_mode=auto --timeout=45 --timeout-method=thread -p no:cacheprovider
      """
    Then the command should succeed
