@upstream
Feature: upstream test_timeouts.py::test_cancel_wait_timeout

  One pytest test from the official PgBouncer suite, vendored
  verbatim into testkit/upstream/pgbouncer/. The harness starts
  a fresh PostgreSQL and pooler (Background), then runs the test.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_cancel_wait_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_cancel_wait_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed
