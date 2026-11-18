@upstream
@supported-pgbouncer @unadapted-odyssey @unadapted-pg_doorman
Feature: upstream test_operations.py::test_database_restart

  Adapted from PgBouncer 1.26.1. Native setup profile: default.
  One pytest node, a fresh PostgreSQL and a fresh pooler per scenario.
  Required extra resources: none.
  pgbouncer: supported
  odyssey: unadapted: native retry setup not yet mapped
  pg_doorman: unadapted: native retry setup not yet mapped

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_database_restart
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} timeout --kill-after=5s 70s python3 -m pytest -q "test_operations.py::test_database_restart" -o asyncio_mode=auto --timeout=45 --timeout-method=thread -p no:cacheprovider
      """
    Then the command should succeed
