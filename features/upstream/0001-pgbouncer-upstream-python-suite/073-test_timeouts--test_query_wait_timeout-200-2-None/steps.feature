@upstream
@supported-pgbouncer @unadapted-odyssey @unsupported-pg_doorman
Feature: upstream test_timeouts.py::test_query_wait_timeout_scope[200-2-None]

  Adapted from PgBouncer 1.26.1. Native setup profile: default.
  One pytest node, a fresh PostgreSQL and a fresh pooler per scenario.
  Required extra resources: none.
  pgbouncer: supported
  odyssey: unadapted: PgBouncer user/database override precedence; Doorman only exposes the global wait limit
  pg_doorman: unsupported: pinned Doorman sources acquisition timeout from general.query_wait_timeout, without user/database overrides

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_query_wait_timeout_scope (200-2-None)
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} timeout --kill-after=5s 70s python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout_scope[200-2-None]" -o asyncio_mode=auto --timeout=45 --timeout-method=thread -p no:cacheprovider
      """
    Then the command should succeed
