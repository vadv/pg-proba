@selectin
Feature: selectin through pooler

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/cache2-size1"

  # ============================================================================
  # CORE BUG: Cache eviction during async_mode=true causes protocol desync
  # ============================================================================

  Scenario: selectin client passes all queries
    When I run shell command:
      """
      cd testkit/drivers/python && \
      python3 ./test_selectin_bug.py \
        --host 127.0.0.1 \
        --port ${DOORMAN_PORT} \
        --user example_user_1 \
        --password test \
        --dbname example_db \
        --iterations 100 \
        --workers 2
      """
    Then the command should succeed
    And the command output should contain "All queries passed successfully"
