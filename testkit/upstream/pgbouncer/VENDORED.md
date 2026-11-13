# Vendored: официальный Python-сьют PgBouncer

- **Источник:** <https://github.com/pgbouncer/pgbouncer>, тег `pgbouncer_1_26_1`, каталог `test/`
- **Лицензия:** ISC (pgbouncer)

## Что скопировано (без изменений)

- `__init__.py`, `utils.py`
- `../include/bouncer.h` → `testkit/upstream/include/bouncer.h`
  (читается `utils.py` при импорте: `#define MAX_PASSWORD 65531`)
- `test_prepared.py`, `test_copy.py`, `test_cancel.py`, `test_operations.py`,
  `test_timeouts.py`, `test_no_database.py`, `test_no_user.py`

## Что НЕ вендорено

- `conftest.py` — заменён нашим адаптером: upstream поднимает собственные
  PostgreSQL и PgBouncer на каждый прогон, у нас их стартует cucumber-харнесс
  (`features/upstream/0001-pgbouncer-upstream-python-suite/steps.feature`);
  адаптер биндит фикстуры `pg`/`bouncer` к уже запущенным инстансам и
  пропускает тесты, требующие владения процессом (см. docstring conftest.py)
- прочие `test_*.py`, `pgbouncer.ini`/`userlist.txt` (свой профиль —
  `testkit/configs/upstream/`), C-тесты, docker-compose обвязка

## Обновление

```console
$ git clone --depth 1 --branch pgbouncer_1_XX_Y https://github.com/pgbouncer/pgbouncer
$ cp pgbouncer/test/{__init__,utils,test_prepared,test_copy,test_cancel,test_operations,test_timeouts,test_no_database,test_no_user}.py .
```

Обновлять файлы можно только целым набором: `utils.py` и тесты связаны
версией между собой. После обновления — прогнать
`env/run.sh test pgbouncer features/upstream/0001-*/steps.feature` и
разобрать падения.
- `../build/test_config.h` → `testkit/upstream/build/test_config.h` (meson-style флаги сборки: TLS yes, LDAP no — по факту бинарника в образе; читается `utils.py` при импорте)
