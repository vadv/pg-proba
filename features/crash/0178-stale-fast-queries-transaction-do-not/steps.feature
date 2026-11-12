@stale
Feature: Fast queries in transaction

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied

  Scenario: no false detection
    # A client sending queries with small gaps (<100ms) must never hit
    # the server-monitoring code path — no false ServerDead detection.
    Given pooler started with config from "testkit/configs/size1"
    When we create session "fast" to pooler as "example_user_1" with password "" and database "example_db"
    When we send SimpleQuery "BEGIN" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    # Rapid-fire 10 queries — none should fail
    When we send SimpleQuery "SELECT 1" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    When we send SimpleQuery "SELECT 2" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "2"
    When we send SimpleQuery "SELECT 3" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "3"
    When we send SimpleQuery "SELECT 4" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "4"
    When we send SimpleQuery "SELECT 5" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "5"
    When we send SimpleQuery "SELECT 6" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "6"
    When we send SimpleQuery "SELECT 7" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "7"
    When we send SimpleQuery "SELECT 8" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "8"
    When we send SimpleQuery "SELECT 9" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "9"
    When we send SimpleQuery "SELECT 10" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
    Then session "fast" should receive DataRow with "10"
    # Transaction completes normally
    When we send SimpleQuery "COMMIT" to session "fast" without waiting
    Then we read SimpleQuery response from session "fast" within 2000ms
