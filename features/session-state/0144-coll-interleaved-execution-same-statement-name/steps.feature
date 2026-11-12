@coll
Feature: Name collision: interleaved execution

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache100-size1"

  Scenario: results match clients
    # Create all three clients first
    When we create session "alpha" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "beta" to pooler as "example_user_1" with password "" and database "example_db"
    And we create session "gamma" to pooler as "example_user_1" with password "" and database "example_db"
    # Each client parses "shared_name" with different query
    And we send Parse "shared_name" with query "select 'ALPHA'::text as client" to session "alpha"
    And we send Sync to session "alpha"
    And we send Parse "shared_name" with query "select 'BETA'::text as client" to session "beta"
    And we send Sync to session "beta"
    And we send Parse "shared_name" with query "select 'GAMMA'::text as client" to session "gamma"
    And we send Sync to session "gamma"
    # Interleaved execution - execute in different order than parse
    When we send Bind "" to "shared_name" with params "" to session "gamma"
    And we send Execute "" to session "gamma"
    And we send Sync to session "gamma"
    Then session "gamma" should receive DataRow with "GAMMA"
    When we send Bind "" to "shared_name" with params "" to session "alpha"
    And we send Execute "" to session "alpha"
    And we send Sync to session "alpha"
    Then session "alpha" should receive DataRow with "ALPHA"
    When we send Bind "" to "shared_name" with params "" to session "beta"
    And we send Execute "" to session "beta"
    And we send Sync to session "beta"
    Then session "beta" should receive DataRow with "BETA"
