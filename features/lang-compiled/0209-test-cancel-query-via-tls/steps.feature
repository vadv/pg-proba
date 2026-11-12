@lang-go
Feature: cancel request over TLS must interrupt query
  Go client (lib/pq + manual TLS): session runs pg_sleep, cancel
  request is sent over a SEPARATE TLS connection (SSLRequest +
  CancelRequest, real backend PID from pg_backend_pid()).
  Direct PG accepts TLS cancel: query aborts, client gets
  57014 query_canceled. Pooler under TLS must forward it too.
  Profile cache100: pooler TLS enabled.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: cancel of long query over TLS
    When I run shell command:
      """
      export DATABASE_URL="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db?sslmode=disable"
      cd testkit/drivers/go && go test -v -run TestCancelTLSQuery ./extended
      """
    Then the command should succeed
    And the command output should contain "PASS: TestCancelTLSQuery"
