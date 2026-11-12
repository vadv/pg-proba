@copy
Feature: COPY inside rolled-back transaction

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/default"

  Scenario: identical to direct PostgreSQL
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send SimpleQuery "BEGIN" to both
    And we send SimpleQuery "CREATE TEMP TABLE copy_rollback_test (id int)" to both
    And we send CopyFromStdin "COPY copy_rollback_test FROM STDIN" with data "1\n2\n3\n" to both
    And we send SimpleQuery "ROLLBACK" to both
    And we send SimpleQuery "SELECT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'copy_rollback_test')" to both
    Then we should receive identical messages from both
