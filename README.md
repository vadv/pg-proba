# pg-proba

Differential test suite for PostgreSQL connection poolers: **PgBouncer**, **Odyssey**, and **pg_doorman**.

All three poolers run the same 347 scenarios in transaction pooling mode with prepared statement caching enabled. Direct PostgreSQL 16 is the reference: a test passes when a client talking to the pooler sees the same behavior as against PostgreSQL itself.

The corpus comes from two sources:

- **246 protocol and driver scenarios** (`features/protocol/`, `copy-cancel/`, `session-state/`, `crash/`, `lang-*/`) — derived from the pg_doorman BDD suite (MIT) and split into one-behavior-per-test scenarios. They cover raw wire-protocol message parity (`Parse`/`Bind`/`Execute`/`Flush`/`Sync`) and real client drivers (`libpq`, `psycopg2`/`psycopg3`, `pgjdbc`, `Npgsql`, `pgx`, `node-postgres`, `PDO`).
- **101 PgBouncer test suite scenarios** (`features/upstream/`, vendored from PgBouncer 1.26.1 under ISC at `testkit/upstream/pgbouncer/`) — one pytest test per scenario. Runtime admin-console setup (`SET`/`RELOAD`) is replaced with static config profiles (`testkit/upstream/cases.tsv` + `generate.py`). Tests that rely on features a pooler does not implement by design are marked **N/A**; tests not yet wired up for a pooler are marked **Unadapted**. Neither is counted as PASS.

Each scenario lives in `features/<category>/<id>/steps.feature` and points to the exact pooler and PostgreSQL configs it runs with. All versions (PostgreSQL, the three poolers, and client language runtimes) are pinned in `env/flake.lock`.

## Results

347 scenarios × 3 poolers:

| Pooler | PASS | FAIL | N/A | Unadapted | Pass rate (PASS / runnable) |
|---|---:|---:|---:|---:|---:|
| pg_doorman | 292 | 10 | 29 | 16 | 96.7% (292 / 302) |
| pgbouncer | 342 | 5 | 0 | 0 | 98.6% (342 / 347) |
| odyssey | 303 | 5 | 16 | 23 | 98.4% (303 / 308) |

### Failing tests

| Test | odyssey | pgbouncer | pg_doorman |
|---|---|---|---|
| [0129](features/protocol/0129-batch-batch-flush-between-parse-operations/steps.feature) **Pipeline `Parse` + `Flush` hangs**: when a client sends `Parse` followed by `Flush` (without `Sync`) for an already-cached statement, PgBouncer swallows `Parse`, queues a synthetic `ParseComplete` in `client->sbuf`, and does not flush it until `Sync`. A client waiting for the `Flush` response before sending `Bind` deadlocks ([pgbouncer#1704](https://github.com/pgbouncer/pgbouncer/issues/1704)). | ✓ | ✗ | ✓ |
| [0141](features/session-state/0141-pcsp-bug-2-sticky-reset-fires/steps.feature) **Startup `search_path` leaks between clients**: startup parameters from client 1's initial packet stay on the backend connection for client 2 unless `pool_smart_discard = yes` (off by default; `pool_discard` cannot be combined with `pool_reserve_prepared_statement`). | ✗ | ✓ | ✓ |
| [0142](features/session-state/0142-pcsp-bug-3-parse-error-does/steps.feature) **Re-`Parse` after a failed `Parse` drops the connection**: PgBouncer records the client statement name before the backend `Parse` finishes. If the backend returns an error (`42P01`), a retry with the same statement name fails in PgBouncer with `prepared statement name is already in use` and disconnects the client ([pgbouncer#1630](https://github.com/pgbouncer/pgbouncer/issues/1630)). | ✓ | ✗ | ✓ |
| [0173](features/session-state/0173-dcc-deallocate-specific-statement-clears-only/steps.feature) **SQL `DEALLOCATE <name>` desynchronizes the statement cache**: `src/server.c` tracks only `DEALLOCATE ALL` and `DISCARD ALL`. A targeted `DEALLOCATE name` drops the statement on PostgreSQL while PgBouncer keeps its cache entry, so the next reuse skips `Parse` and fails with `26000` ([pgbouncer#1705](https://github.com/pgbouncer/pgbouncer/issues/1705), fixed upstream). *(Note: `pg_doorman` replies to `DEALLOCATE name` with a synthetic `CommandComplete` without freeing the backend statement.)* | ✓ | ✗ | ✓ |
| [0226](features/lang-compiled/0226-run-net-multi-session-tests/steps.feature) **`DISCARD ALL` pipelined with `Parse` drops the new statement**: when `SimpleQuery("DISCARD ALL")` is sent in the same TCP batch as the next extended-protocol `Parse` (Npgsql's connection reset pattern), PgBouncer registers the new statement while `DISCARD ALL` is still in flight; the arriving `DISCARD ALL` `CommandComplete` then wipes the newly registered entry (`src/server.c:218`), causing `08P01` (`prepared statement did not exist`) and disconnect ([pgbouncer#1706](https://github.com/pgbouncer/pgbouncer/issues/1706)). | ✓ | ✗ | ✓ |
| [0248](features/lang-jvm-script/0248-run-java-aggressive-mixed-tests-batch-prepared-statements-ex/steps.feature) **Prepared statement lost after a backend execution error**: when a query inside an explicit transaction hits a constraint error (`23505`), Odyssey drops the statement from its server-side map (`apply_delta = 0`) while still returning a virtual `ParseComplete` on retry, so the next `Bind` goes to the server unmapped and fails with `26000` instead of `25P02` ([odyssey#1840](https://github.com/yandex/odyssey/issues/1840), fixed upstream). | ✗ | ✓ | ✓ |
| [0254](features/lang-jvm-script/0254-run-python-session-cursors-tests/steps.feature) **`DECLARE ... CURSOR WITH HOLD` leaks across clients**: in transaction pooling without `server_reset_query` / `DISCARD ALL`, a holdable cursor created by client 1 stays open in `pg_cursors` and can be read by client 2 on the reused backend connection ([pgbouncer#976](https://github.com/pgbouncer/pgbouncer/issues/976)). | ✗ | ✗ | ✓ |
| [009–017](features/upstream/0001-pgbouncer-upstream-python-suite/009-test_copy--test_copy_stdin_success_extended/steps.feature) **Extended-protocol `COPY FROM STDIN` deadlocks** *(6 tests: 009–011, 015–017)*: pg_doorman relays `CopyInResponse` to the client but never forwards the client's `CopyData`/`CopyDone` to PostgreSQL; the client blocks in `PQgetResult()` while the backend waits in `ClientRead` ([pg_doorman#287](https://github.com/ozontech/pg_doorman/issues/287)). | ✓ | ✓ | ✗ |
| [054–055](features/upstream/0001-pgbouncer-upstream-python-suite/054-test_prepared--test_prepared_statement_pipeline/steps.feature) **Pipeline batch with a re-prepared statement name hangs** *(2 tests: 054, 055)*: on a reused backend connection, a pipeline batch that `Parse`s an already-cached statement name with new query text followed by a second `Parse` never completes — hit by any driver with a per-connection statement counter ([pg_doorman#288](https://github.com/ozontech/pg_doorman/issues/288)). | ✓ | ✓ | ✗ |
| [062](features/upstream/0001-pgbouncer-upstream-python-suite/062-test_prepared--test_prepared_statement_pipeline_error_delayed_sync/steps.feature) **Missing `PGRES_PIPELINE_ABORTED` after an in-pipeline error**: after a query fails inside a pipeline with a delayed `Sync`, skipped commands produce no result instead of `PGRES_PIPELINE_ABORTED`, so psycopg raises `ProgrammingError: no result available` instead of `PipelineAborted` ([pg_doorman#289](https://github.com/ozontech/pg_doorman/issues/289), [odyssey#1855](https://github.com/yandex/odyssey/issues/1855)). | ✗ | ✓ | ✗ |
| [060](features/upstream/0001-pgbouncer-upstream-python-suite/060-test_prepared--test_statement_name_longer_than_pkt_buf/steps.feature) **Statement names > 10000 bytes**: PostgreSQL caps `Describe`/`Close` message length at 10000 bytes (`PQ_SMALL_MESSAGE_LIMIT`, while `Parse` is uncapped) and drops the connection on a 16 KB statement name. PgBouncer's test expects `Describe` and `Close` to succeed because PgBouncer intercepts both in its cache without forwarding the name to PostgreSQL. Odyssey forwards them and relays PostgreSQL's disconnect; pg_doorman answers `Describe` from cache but forwards `Close`, dropping the connection. | ✗* | ✓* | ✗ |

\* In test 060, Odyssey (`✗*`) matches direct PostgreSQL, while PgBouncer (`✓*`) masks PostgreSQL's own 10000-byte limit on `Describe`/`Close` via its statement cache. The upstream test assertion is kept unmodified.

## Run

Docker is the only requirement on the host (Nix runs inside the container).

```sh
env/build.sh        # build the test image (first run downloads nixpkgs; cached afterwards)
env/run.sh matrix   # run all 347 scenarios × 3 poolers
env/run.sh test odyssey features/protocol/0001-named-statement-lru/steps.feature
env/run.sh shell    # interactive bash inside the test container
```

## Layout

```
features/          347 scenarios grouped by CI shard: protocol, copy-cancel,
                   session-state, crash, lang-compiled, lang-jvm-script, upstream
testkit/harness/   Cucumber test runner (Rust)
testkit/drivers/   client driver test suites: go, java, dotnet, python, nodejs, php
testkit/configs/   pooler configs per profile (+ certs/; upstream/ holds generated profiles)
testkit/fixtures/  SQL schemas and seed data
testkit/upstream/  vendored PgBouncer 1.26.1 pytest suite (ISC), capability table
                   (cases.tsv), and feature generator (generate.py)
env/               Docker + Nix flake environment (flake.nix, flake.lock, build.sh, run.sh)
```

## Add a test

Create `features/<category>/NNNN-name/steps.feature`. The tag at the top of the file selects the CI shard in `.github/workflows/matrix.yml` (`@msg-parity` → `protocol`, `@lang-go` → `lang-compiled`, `@lang-python` → `lang-jvm-script`, etc.).

Inside shell steps, `${DOORMAN_PORT}` is the active pooler's port (for whichever pooler is under test) and `${PG_PORT}` is direct PostgreSQL.

Shell test example:

```gherkin
@lang-go
Feature: psql hello
  Scenario: select through the pooler
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      """
    And fixtures from "testkit/fixtures/fixture.sql" applied
    Given pooler started with config from "testkit/configs/messages"
    When I run shell command:
      """
      psql "postgresql://example_user_1@127.0.0.1:${DOORMAN_PORT}/example_db" \
        -Atc "select 'hello world';"
      """
    Then the command should succeed
    And the command output should contain "hello world"
```

Wire-protocol parity test (`features/protocol/0005-msg-parity-simple-query/steps.feature`):

```gherkin
@msg-parity
Feature: SimpleQuery: basic query
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
    And we send SimpleQuery "select 1;" to both
    Then we should receive identical messages from both
```

Run the new scenario against a pooler:

```sh
env/run.sh test pg_doorman features/<category>/NNNN-name/steps.feature
```
