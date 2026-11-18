# pg-proba

Differential test suite for PostgreSQL connection poolers (PgBouncer, Odyssey, pg_doorman).

246 protocol and driver scenarios plus 101 scenarios adapted from the upstream PgBouncer
python suite (1.26.1) run against each pooler in transaction mode (with prepared statement
caching enabled) and against direct PostgreSQL 16 as the reference.

## How it works

- **Two test layers**: wire-level extended query protocol assertions (Parse/Bind/Execute/Flush/Sync parity with direct PG) and real client drivers (`libpq`, `psycopg2`/`psycopg3`, `pgjdbc`, `Npgsql`, `pgx`, `node-postgres`, `PDO`).
- **A second corpus: the upstream PgBouncer suite** (ISC, vendored at `testkit/upstream/pgbouncer/`). Setup that upstream performs through the admin console is moved into static per-case config profiles (`testkit/upstream/cases.tsv` + `generate.py`); every case declares per-pooler capability — `unsupported` (by design) or `unadapted` (no workaround yet) with a reason — reported as N/A / UNADAPTED, never as PASS.
- **Self-contained scenarios**: each `features/<category>/NNNN-slug/steps.feature` defines the exact workload and pooler config profile.
- **Reproducible environment**: PostgreSQL, all three poolers, and all language runtimes are pinned in a single Nix flake (`env/flake.lock`).

## Results

347 tests × 3 poolers (246 original + 101 upstream-suite scenarios).
Linux, Docker environment (nix inside the image). The matrix runs on each push.
Upstream-suite rows are measured by local matrix runs (2026-11-15..18) until
the next CI run regenerates them.

| Pooler | PASS | RED | N/A | Unadapted | Coverage (of runnable) |
|---|---|---|---|---|---|
| pg_doorman | 292 | 10 | 29 | 16 | 96.7% |
| pgbouncer | 342 | 5 | 0 | 0 | 98.6% |
| odyssey | 303 | 5 | 16 | 23 | 98.4% |

### Known differences (RED)

| Test | odyssey | pgbouncer | pg_doorman |
|---|---|---|---|
| [0129](features/protocol/0129-batch-batch-flush-between-parse-operations/steps.feature) **Pipeline `Parse` + `Flush` hangs**: when a client sends `Parse` followed by `Flush` (no `Sync`) for an already-cached statement, PgBouncer swallows `Parse`, emits a synthetic `ParseComplete` into `client->sbuf`, and never flushes it until `Sync`. Clients waiting on `Flush` before sending `Bind` deadlock ([pgbouncer#1704](https://github.com/pgbouncer/pgbouncer/issues/1704)). | ✓ | ✗ | ✓ |
| [0141](features/session-state/0141-pcsp-bug-2-sticky-reset-fires/steps.feature) **Startup `search_path` leaks between clients**: startup parameters set in the initial packet by client 1 persist on the backend connection for client 2 unless `pool_smart_discard = yes` (disabled by default; `pool_discard` cannot be combined with `pool_reserve_prepared_statement`). | ✗ | ✓ | ✓ |
| [0142](features/session-state/0142-pcsp-bug-3-parse-error-does/steps.feature) **Re-`Parse` after a failed `Parse` drops the connection**: PgBouncer registers the statement name before backend `Parse` completes; when the backend returns an error (`42P01`), a subsequent `Parse` with the same name fails in PgBouncer with `prepared statement name is already in use` and disconnects the client ([pgbouncer#1630](https://github.com/pgbouncer/pgbouncer/issues/1630)). | ✓ | ✗ | ✓ |
| [0173](features/session-state/0173-dcc-deallocate-specific-statement-clears-only/steps.feature) **SQL `DEALLOCATE <name>` desynchronizes statement cache**: `src/server.c` tracks only `DEALLOCATE ALL` / `DISCARD ALL` command tags. A targeted `DEALLOCATE name` removes the statement on PostgreSQL while PgBouncer keeps the cache entry, so the next reuse skips `Parse` and fails with `26000` ([pgbouncer#1705](https://github.com/pgbouncer/pgbouncer/issues/1705)) — **fixed upstream**, green from the next PgBouncer release. *(Note: `pg_doorman` intercepts `DEALLOCATE name` with a synthetic `CommandComplete` without freeing the backend statement.)* | ✓ | ✗ | ✓ |
| [0226](features/lang-compiled/0226-run-net-multi-session-tests/steps.feature) **`DISCARD ALL` pipelined with `Parse` drops the new statement**: when `SimpleQuery("DISCARD ALL")` is sent in the same TCP batch as the next extended-protocol `Parse` (Npgsql connection reset pattern), PgBouncer registers the new statement while `DISCARD ALL` is still in flight; the arriving `DISCARD ALL` `CommandComplete` wipes the freshly registered entry (`src/server.c:218`), causing `08P01` (`prepared statement did not exist`) and disconnect ([pgbouncer#1706](https://github.com/pgbouncer/pgbouncer/issues/1706)). | ✓ | ✗ | ✓ |
| [0248](features/lang-jvm-script/0248-run-java-aggressive-mixed-tests-batch-prepared-statements-ex/steps.feature) **Prepared statement lost on backend execution error**: when a batch/statement inside an explicit transaction hits a constraint error (e.g. `23505`), Odyssey drops the statement from its server-side map while injecting virtual `ParseComplete` on retry (`OD_XPLAN_VIRTUAL_PARSE_COMPLETE`), sending an unparsed `Bind` that fails with `26000` instead of `25P02` ([odyssey#1840](https://github.com/yandex/odyssey/issues/1840)) — **fixed upstream**. | ✗ | ✓ | ✓ |
| [0254](features/lang-jvm-script/0254-run-python-session-cursors-tests/steps.feature) **`DECLARE ... CURSOR WITH HOLD` leaks across clients**: in transaction pooling without `server_reset_query` / `DISCARD ALL`, a holdable cursor created by client 1 remains open in `pg_cursors` and readable by client 2 on the reused backend connection ([pgbouncer#976](https://github.com/pgbouncer/pgbouncer/issues/976)). | ✗ | ✗ | ✓ |
| [009](features/upstream/0001-pgbouncer-upstream-python-suite/009-test_copy--test_copy_stdin_success_extended/steps.feature) **Extended-protocol `COPY FROM STDIN` deadlocks** (upstream suite, 009–017): pg_doorman relays `CopyInResponse` but never forwards the client's `CopyData`/`CopyDone`; the client blocks in `PQgetResult()` forever while the backend waits in `ClientRead` ([pg_doorman#287](https://github.com/ozontech/pg_doorman/issues/287)). | ✓ | ✓ | ✗ |
| [054](features/upstream/0001-pgbouncer-upstream-python-suite/054-test_prepared--test_prepared_statement_pipeline/steps.feature) **Pipeline batch with a re-prepared statement name hangs** (upstream suite, 054–055): on a reused server connection, a `Parse` under a name already cached with different text plus a second `Parse` in the same pipeline batch never completes — any driver with a per-connection statement counter hits this behind a transaction pooler ([pg_doorman#288](https://github.com/ozontech/pg_doorman/issues/288)). | ✓ | ✓ | ✗ |
| [062](features/upstream/0001-pgbouncer-upstream-python-suite/062-test_prepared--test_prepared_statement_pipeline_error_delayed_sync/steps.feature) **No `PGRES_PIPELINE_ABORTED` after an in-pipeline error** (upstream suite): commands of the aborted batch segment produce no result — psycopg raises `ProgrammingError: no result available` instead of `PipelineAborted`, so an app cannot tell a skipped batch from a desync ([pg_doorman#289](https://github.com/ozontech/pg_doorman/issues/289), [odyssey#1855](https://github.com/yandex/odyssey/issues/1855)). | ✗ | ✓ | ✗ |
| [060](features/upstream/0001-pgbouncer-upstream-python-suite/060-test_prepared--test_statement_name_longer_than_pkt_buf/steps.feature) **Statement names > 10000 bytes** (upstream suite): direct PG itself drops the connection on `Describe`/`Close` of that size (`invalid message length`, no ErrorResponse; `Parse` has no cap — `PQ_SMALL_MESSAGE_LIMIT`). Odyssey relays the drop byte-for-byte like direct PG — its RED is the test encoding PgBouncer's answer-from-cache behavior; pg_doorman answers `Describe` from its cache but forwards the raw `Close`, losing the client connection. | ✗* | ✓* | ✗ |

\* 060's verdict is inverted relative to the direct-PG oracle: the pooler marked RED (odyssey) matches direct PostgreSQL exactly, while the PASS (pgbouncer) hides the server's own disconnect behind its statement cache. The expectation is kept exactly as upstream wrote it.

## Run

Docker is the only requirement.

```sh
env/build.sh        # build the image (the first build is slow, later builds use the cache)
env/run.sh matrix   # the full matrix: each test × 3 poolers
env/run.sh test odyssey features/protocol/0001-named-statement-lru/steps.feature
env/run.sh shell    # bash inside the environment
```

PostgreSQL, pooler, and language versions are pinned in `env/flake.lock`.

Supported poolers: **pg_doorman**, **odyssey**, **pgbouncer**.

## Layout

```
features/          scenarios by category (= CI shards): protocol, copy-cancel,
                   session-state, crash, lang-compiled, lang-jvm-script, upstream
testkit/harness/   cucumber harness (Rust)
testkit/drivers/   driver test sources: go, java, dotnet, python, nodejs, php
testkit/configs/   base pooler config profiles (+ certs/; upstream/ holds generated
                   per-case profiles)
testkit/fixtures/  shared SQL fixtures
testkit/upstream/  vendored upstream PgBouncer suite (ISC) + triage table
                   (cases.tsv) + generator (generate.py)
env/               Docker environment (nix flake)
```

## Add a test

Create a new directory `features/<category>/NNNN-name/` with one
`steps.feature` file. The tag above `Feature:` selects the CI shard:
`@lang-go`/`@lang-dotnet` → lang-compiled, `@lang-java`/`@lang-python`/…
→ lang-jvm-script, `@msg-parity`/… → protocol, and so on
(full list: `.github/workflows/matrix.yml`).

Shell steps see `${DOORMAN_PORT}` (the port of the current pooler) and
`${PG_PORT}`.

The simplest test is a shell step with psql:

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

A protocol test uses BDD steps with sessions and compares the pooler with
direct PostgreSQL (a real file, `features/protocol/0005-msg-parity-simple-query/steps.feature`):

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

Local run without CI (inside the docker image):

```sh
docker run --rm -v "$PWD:/workspace" -w /workspace --tmpfs /tmp:exec \
  -e CARGO_TARGET_DIR=/tmp/target -e POOLER=pg_doorman \
  -e FEATURES=features/<new-test>/steps.feature \
  pg-proba-test-env:latest cargo test --test bdd
```
