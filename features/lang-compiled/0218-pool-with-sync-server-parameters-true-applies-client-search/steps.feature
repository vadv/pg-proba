@lang-go
Feature: startup search_path applied on server
  Client sends search_path=bucket_0 in startup packet
  (lib/pq DSN ?search_path=bucket_0). Direct PG applies GUC
  at session start: SHOW search_path = bucket_0. Transparent
  pooler must do the same.
  Profile cache100-sync: all poolers transaction mode;
  pg_doorman sync_server_parameters = true; pgbouncer
  track_extra_parameters = search_path; odyssey tracks
  startup vars natively.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-sync"

  Scenario: client search_path applied on server
    Go test Test_SyncServerParametersWithSearchPath:
    connect with search_path in DSN, then SHOW search_path.
    Expect bucket_0.
    When I run shell command:
      """
      export DATABASE_URL_WITH_SEARCH_PATH="postgresql://example_user_1:test@127.0.0.1:${DOORMAN_PORT}/example_db?sslmode=disable&search_path=bucket_0"
      cd testkit/drivers/go && go test -v -run Test_SyncServerParametersWithSearchPath ./sync-parameters
      """
    Then the command should succeed
    And the command output should contain "PASS: Test_SyncServerParametersWithSearchPath"
