@lang-python
Feature: Python psycopg2: server-side cursors
  DECLARE ... CURSOR WITH HOLD in one connection, then a NEW
  connection lists pg_cursors. Direct PG: closing the first client
  session destroys its cursors, the second session sees none.
  Pooler must keep that illusion: no cross-client cursor leak
  (and no mangled statement text). Profile lang40.
  Verdict (2026-11-12, probes repro/odyssey-0254, repro/pgbouncer-0254):
  session-feature limitation, documented by both — pgbouncer doc/config.md
  ("clients must not use any session-based features" in transaction pooling),
  odyssey docs/features/pooling.md ("transaction pooling does not preserve
  session state"). Statement text is delivered verbatim by both; the earlier
  "mangled text" reading of the CI log was an artifact (BEGIN logged as a
  separate packet). Cross-client cursor leak confirmed on both poolers.
  Neither doc warns that the object becomes VISIBLE to the next client.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/lang40"

  Scenario: cursors with session hold
    When I run shell command:
      """
      cd testkit/drivers/python && \
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db" && \
      python3 ./test_session_cursors.py
      """
    Then the command should succeed
