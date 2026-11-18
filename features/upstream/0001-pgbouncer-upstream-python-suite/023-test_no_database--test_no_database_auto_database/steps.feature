@upstream
@supported-pgbouncer @supported-odyssey @unsupported-pg_doorman
Feature: upstream test_no_database.py::test_no_database_auto_database

  Adapted from PgBouncer 1.26.1. Native setup profile: wildcard.
  One pytest node, a fresh PostgreSQL and a fresh pooler per scenario.
  Required extra resources: none.
  pgbouncer: supported
  odyssey: supported
  pg_doorman: unsupported: pinned Doorman configuration requires an explicit database pool; no wildcard database route

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream/wildcard"

  Scenario: test_no_database_auto_database
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} timeout --kill-after=5s 70s python3 -m pytest -q "test_no_database.py::test_no_database_auto_database" -o asyncio_mode=auto --timeout=45 --timeout-method=thread -p no:cacheprovider
      """
    Then the command should succeed
