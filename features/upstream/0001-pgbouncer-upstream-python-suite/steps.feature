@upstream
Feature: Upstream PgBouncer Python suite (vendored @ pgbouncer_1_26_1)

  The 102 pytest tests of the official PgBouncer suite, vendored verbatim
  from tag pgbouncer_1_26_1 into testkit/upstream/pgbouncer/ (provenance in
  VENDORED.md there). conftest.py in that directory is our adapter:
  PostgreSQL and the pooler are already started by the harness; tests bind
  to them.

  One pytest test = one Scenario: each gets its own Background, so the
  harness starts a fresh pooler per test - the same semantics as upstream's
  function-scoped fixtures. Tests that need runtime config rewrites via
  bouncer.run_with_config(), network fault injection or PG restarts skip
  themselves cleanly (pytest.skip in conftest); everything else connects
  through the testkit/configs/upstream profile (max_prepared_statements =
  200 - probes in #2: with 0, stock 1.26.1 in statement mode returns
  DuplicatePreparedStatement on a reused server connection; 200 is the tag
  default maximum; tests that need a specific value set it via admin).

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_cancel.py: test_cancel
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_cancel.py::test_cancel" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_cancel.py: test_cancel_wait
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_cancel.py::test_cancel_wait" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_cancel.py: test_cancel_pool_size
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_cancel.py::test_cancel_pool_size" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_cancel.py: test_cancel_race
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_cancel.py::test_cancel_race" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_success_simple
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_success_simple" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_before_copy_done_simple
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_before_copy_done_simple" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_after_copy_done_simple
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_after_copy_done_simple" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdout_simple
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdout_simple" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_success_extended
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_success_extended" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_before_copy_done_extended
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_before_copy_done_extended" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_after_copy_done_extended
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_after_copy_done_extended" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdout_extended
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdout_extended" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_before_copy_done_transaction_pool
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_before_copy_done_transaction_pool" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_before_copy_done_in_transaction
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_before_copy_done_in_transaction" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_success_prepared
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_success_prepared" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_before_copy_done_prepared
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_before_copy_done_prepared" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdin_error_after_copy_done_prepared
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdin_error_after_copy_done_prepared" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_copy.py: test_copy_stdout_prepared
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_copy.py::test_copy_stdout_prepared" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_authfail
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_authfail" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_auth_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_auth_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_pg
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_pg" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_auto_database
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_auto_database" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_auto_database_auth_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_auto_database_auth_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_md5_auth_scram_pw_success
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_md5_auth_scram_pw_success" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_scram_auth_scram_pw_success
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_scram_auth_scram_pw_success" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py: test_no_database_md5_auth_md5_pw_success
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_database.py::test_no_database_md5_auth_md5_pw_success" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_trust
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_trust" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_trust_forced_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_trust_forced_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_password
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_password" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_password_forced_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_password_forced_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_md5
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_md5" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_md5_forced_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_md5_forced_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_scram
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_scram" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_scram_forced_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_scram_forced_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_auth_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_auth_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py: test_no_user_auth_user_null_row
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_no_user.py::test_no_user_auth_user_null_row" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_operations.py: test_pause_resume
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_operations.py::test_pause_resume" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_operations.py: test_enable_disable
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_operations.py::test_enable_disable" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_operations.py: test_database_restart
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_operations.py::test_database_restart" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_operations.py: test_database_change
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_operations.py::test_database_change" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_operations.py: test_reconnect
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_operations.py::test_reconnect" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_params
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_params" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_discard_or_deallocate_all[DISCARD ALL]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_discard_or_deallocate_all[DISCARD ALL]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_discard_or_deallocate_all[DEALLOCATE ALL]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_discard_or_deallocate_all[DEALLOCATE ALL]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_parse_larger_than_pkt_buf
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_parse_larger_than_pkt_buf" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_bind_larger_than_pkt_buf
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_bind_larger_than_pkt_buf" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_parse_larger_than_pkt_buf_but_smaller_than_4x
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_parse_larger_than_pkt_buf_but_smaller_than_4x" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_bind_larger_than_pkt_buf_but_smaller_than_4x
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_bind_larger_than_pkt_buf_but_smaller_than_4x" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_parse_larger_than_pkt_buf_with_varcache_change
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_parse_larger_than_pkt_buf_with_varcache_change" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_evict_statement_cache
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_evict_statement_cache" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_evict_statement_cache_pipeline_failure
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_evict_statement_cache_pipeline_failure" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_pipeline
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_pipeline" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_pipeline_stress
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_pipeline_stress" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_describe_non_existent_prepared_statement
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_describe_non_existent_prepared_statement" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_close_prepared_statement
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_close_prepared_statement" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_close_batched_with_reused_parse
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_close_batched_with_reused_parse" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_close_batched_with_evicting_parse
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_close_batched_with_evicting_parse" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_statement_name_longer_than_pkt_buf
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_statement_name_longer_than_pkt_buf" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_pipeline_error
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_pipeline_error" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_pipeline_error_delayed_sync
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_pipeline_error_delayed_sync" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_failed_prepare
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_failed_prepare" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_failed_prepare_pipeline
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_failed_prepare_pipeline" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_disallow_name_reuse
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_disallow_name_reuse" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_pipeline_with_half_pkt_buf_prepare
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_pipeline_with_half_pkt_buf_prepare" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_pipeline_flushes_on_full_pkt_buf
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_pipeline_flushes_on_full_pkt_buf" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_pause_before_last_sync
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_pause_before_last_sync" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_pipeline_latency
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_pipeline_latency" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_prepared.py: test_prepared_statement_counters
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_prepared.py::test_prepared_statement_counters" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_wait_timeout[2-None-None]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout[2-None-None]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_wait_timeout[None-2-None]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout[None-2-None]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_wait_timeout[200-2-None]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout[200-2-None]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_wait_timeout[None-None-2]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout[None-None-2]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_wait_timeout[200-None-2]
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout[200-None-2]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_lifetime
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_lifetime" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_lifetime_per_pool
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_lifetime_per_pool" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_idle_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_idle_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_idle_transaction_timeout_negative
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_idle_transaction_timeout_negative" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_idle_transaction_timeout_override_global
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_idle_transaction_timeout_override_global" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_idle_transaction_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_idle_transaction_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_query_timeout_override_global
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_query_timeout_override_global" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_query_timeout_negative
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_query_timeout_negative" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_query_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_query_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_level_idle_client_timeout_negative
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_level_idle_client_timeout_negative" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_level_idle_client_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_level_idle_client_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_user_level_idle_client_timeout_override
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_user_level_idle_client_timeout_override" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_transaction_timeout_user_overide_global
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_transaction_timeout_user_overide_global" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_transaction_timeout_user
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_transaction_timeout_user" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_transaction_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_transaction_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_idle_transaction_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_idle_transaction_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_client_idle_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_client_idle_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_pool_idle_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_pool_idle_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_pool_idle_timeout_ignores_min_pool_size
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_pool_idle_timeout_ignores_min_pool_size" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_login_retry
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_login_retry" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_connect_timeout_establish
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_connect_timeout_establish" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_connect_timeout_drop_traffic
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_connect_timeout_drop_traffic" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_tcp_user_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_tcp_user_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_server_check_delay
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_server_check_delay" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_cancel_wait_timeout
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_cancel_wait_timeout" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py: test_query_timeout_when_no_active_query
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} PGBOUNCER_INI=${PGBOUNCER_CONFIG} PGBOUNCER_LOG=${PGBOUNCER_LOG} PGBOUNCER_USERLIST=${PGBOUNCER_USERLIST} python3 -m pytest -q "test_timeouts.py::test_query_timeout_when_no_active_query" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed
