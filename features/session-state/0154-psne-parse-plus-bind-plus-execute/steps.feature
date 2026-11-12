@psne
Feature: Parse+Bind+Execute without Sync, abort

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: next client gets no garbage
    Given pooler started with config from "testkit/configs/cache100-size1"
    # Full batch without Sync — everything is in client buffer, nothing sent to PG
    When we create session "one" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select $1::int + $2::int" to session "one"
    And we send Bind "" to "s1" with params "1, 2" to session "one"
    And we send Execute "" to session "one"
    # No Sync!
    And we close session "one"
    And we sleep 200ms
    When we create session "two" to pooler as "example_user_1" with password "" and database "example_db"
    And we send Parse "s1" with query "select $1::int + $2::int" to session "two"
    And we send Bind "" to "s1" with params "10, 20" to session "two"
    And we send Execute "" to session "two"
    And we send Sync to session "two"
    Then session "two" should receive DataRow with "30"
