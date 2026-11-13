@upstream
Feature: Upstream PgBouncer Python suite (vendored @ pgbouncer_1_26_1)

  Семь pytest-файлов официального сьюта pgbouncer, вендоренных без изменений
  из тега pgbouncer_1_26_1 в testkit/upstream/pgbouncer/ (провенанс —
  VENDORED.md там же). conftest.py в этом каталоге — наш адаптер: PostgreSQL
  и пулер уже запущены харнессом, тесты подключаются к ним.

  Пока в срезе 1 тесты, которым нужны перезапись конфига на лету, лог-файл
  пулера, сетевые сбои или рестарты PG, честно пропускаются (pytest.skip);
  подключение остальных проходит через профиль testkit/configs/upstream.

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "testkit/configs/upstream"

  Scenario: test_copy.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_copy.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  # 002: два теста временно исключены (триаж в эпике #51):
  #  - test_evict_statement_cache_pipeline_failure: на прямом PG с тем же
  #    psycopg 3.3.6 execute откладывает ошибку до sync, через пулер из образа
  #    (nixpkgs 1.26.1) — поднимает в execute; A/B-проба в #51
  #  - test_prepared_statement_counters: счётчики SHOW STATS у upstream
  #    считаются от нуля (их фикстура поднимает пулер на каждый тест),
  #    у нас один пулер на файл — значения накапливаются (883 ≠ 0)
  Scenario: test_prepared.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_prepared.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider -k 'not test_evict_statement_cache_pipeline_failure and not test_prepared_statement_counters'
      """
    Then the command should succeed

  Scenario: test_cancel.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_cancel.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_operations.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_operations.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_timeouts.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_timeouts.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_database.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_no_database.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed

  Scenario: test_no_user.py
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${DOORMAN_PORT} PG_PORT=${PG_PORT} python3 -m pytest -q test_no_user.py -o asyncio_mode=auto --timeout=120 -p no:cacheprovider
      """
    Then the command should succeed
