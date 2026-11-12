@lang-go
Feature: statement cache limit declared in config must hold
  pgx prepares 150 distinct named statements in one session,
  then counts pg_prepared_statements on the server.
  Policy test, not oracle parity: a pooler that DECLARES a cache
  limit in its config must evict server-side (doorman
  prepared_statements_cache_size=100, pgbouncer
  max_prepared_statements=100 -> count <= 100). A pooler with
  no cache-limit knob (odyssey) must behave like direct PG:
  nothing evicted within the session (count >= 150).
  Profile cache100.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100"

  Scenario: 150 different Parses respect declared cache policy
    Branch by pooler config capability, visible in the command:
    When I run shell command:
      """
      export DATABASE_URL="postgresql://example_user_1:@127.0.0.1:${DOORMAN_PORT}/example_db?sslmode=disable"
      case "${POOLER}" in
        odyssey) export EXPECTED_CACHE_MODE=nolimit ;;
        *)       export EXPECTED_CACHE_MODE=limit ;;
      esac
      cd testkit/drivers/go && go test -v -run TestIssueReproPreparedCache ./prepared
      """
    Then the command should succeed
    And the command output should contain "PASS: TestIssueReproPreparedCache"
