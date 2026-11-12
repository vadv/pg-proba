@lang-python
Feature: Python psycopg3 pipeline: pool-recycle reset + re-prepare
  A recycled connector resets its session with DISCARD ALL and the
  next prepared statement is prepared in the same pipelined batch —
  Npgsql does this on connector reuse, psycopg3 apps do it in
  pipeline mode. Direct PG: DISCARD deallocates only statements
  prepared BEFORE it; the fresh Parse after the reset is valid and
  executable. A transaction pooler must not apply the DISCARD
  retroactively to mappings registered by that Parse (0226 root
  cause: free_client_prepared_statements on CommandComplete
  "DISCARD ALL" wipes the just-registered client mapping -> Bind
  "not found" -> client connection killed). Profile lang40.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: pipelined reset + re-prepare survives
    When I run shell command:
      """
      cd testkit/drivers/python && \
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db" && \
      python3 ./test_pool_recycle_pipeline.py
      """
    Then the command should succeed
    And the command output should contain "PASS:"
