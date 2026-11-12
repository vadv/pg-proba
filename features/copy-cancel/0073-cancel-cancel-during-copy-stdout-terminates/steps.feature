@cancel
Feature: Cancel: during COPY TO STDOUT

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/size1"

  Scenario: copy terminated with canceling error
    When we create session "main" to pooler as "example_user_1" with password "" and database "example_db" and store backend key
    # Start a large COPY that will take some time
    And we send SimpleQuery "COPY (SELECT generate_series(1, 10000000)) TO STDOUT" to session "main" without waiting
    And we sleep 200ms
    And we send cancel request for session "main"
    # Should receive cancellation error
    Then session "main" should receive cancel error containing "canceling"
