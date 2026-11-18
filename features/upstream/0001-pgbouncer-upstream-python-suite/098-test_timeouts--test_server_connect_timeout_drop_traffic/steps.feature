@upstream
@network
@supported-pgbouncer @unsupported-odyssey @unsupported-pg_doorman
Feature: upstream test_timeouts.py::test_server_connect_timeout_drop_traffic

  Adapted from PgBouncer 1.26.1. Native setup profile: default.
  One pytest node, a fresh PostgreSQL and a fresh pooler per scenario.
  Required extra resources: network.
  pgbouncer: supported
  odyssey: unsupported: pinned pooler has no query-execution timeout required by this assertion
  pg_doorman: unsupported: pinned pooler has no query-execution timeout required by this assertion

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_server_connect_timeout_drop_traffic
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} bash ../run_network.sh "test_timeouts.py::test_server_connect_timeout_drop_traffic"
      """
    Then the command should succeed
