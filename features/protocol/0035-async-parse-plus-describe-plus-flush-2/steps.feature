@async
Feature: Flush: Parse + Describe named (asyncpg COPY pattern)

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/messages"
  Scenario: identical to direct PostgreSQL
    When we login to postgres and pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "__asyncpg_stmt_1__" with query "SELECT 1 as col" to both
    And we send Describe "S" "__asyncpg_stmt_1__" to both
    And we send Flush to both
    And we verify partial response received from both
    And we send Bind "" to "__asyncpg_stmt_1__" with params "" to both
    And we send Execute "" to both
    And we send Sync to both
    Then we should receive identical messages from both
