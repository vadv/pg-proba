# pg-proba

Every pooler faces the proba. The proba is PostgreSQL itself.

Differential correctness engine for PostgreSQL connection poolers. Each test compares
pooler behavior with a direct connection to PostgreSQL. PgBouncer, Odyssey,
and pg_doorman run the same suite of tests. The result is an honest summary:
what each pooler does correctly, and what it does not.

## Method

A test passes when the pooler is not distinguishable from direct
PostgreSQL: same protocol, same answers, same state. Each difference is
RED. A RED result is an observation, not a verdict. The pooler can have
a design reason for the difference.

- One test is one file. `features/<category>/NNNN-slug/steps.feature` holds
  the scenario and the full configs of all three poolers. The harness
  substitutes the ports automatically.
- Scenarios read as text. Each step is a natural-language sentence
  (`When I run shell command…`, `Then the command should succeed`).
  The pooler config is visible in the scenario, not hidden in a render.
- One engine runs all poolers. A Rust cucumber harness executes the steps.

## Results

246 tests × 3 poolers. Linux, Docker environment (nix inside the image).
The matrix runs on each push.

| Pooler | PASS | RED | Coverage |
|---|---|---|---|
| pg_doorman | 246 | 0 | 100% |
| pgbouncer | 241 | 5 | 98.0% |
| odyssey | 243 | 3 | 98.8% |

### Known differences (RED)

| Test | odyssey | pgbouncer | pg_doorman |
|---|---|---|---|
| [0129](features/protocol/0129-batch-batch-flush-between-parse-operations/steps.feature) psycopg3/libpq pipeline re-Prepare of a tracked name on a reused server connection: pgbouncer holds ParseComplete back until Sync, the pipeline hangs (direct PG answers in <1 ms; upstream [pgbouncer#1704](https://github.com/pgbouncer/pgbouncer/issues/1704)). Threat: prepared statement preparation deadlocks behind the pooler | ✓ | ✗ | ✓ |
| [0141](features/session-state/0141-pcsp-bug-2-sticky-reset-fires/steps.feature) a startup parameter of client 1 (search_path in this test) survives to client 2 on the same server connection. Odyssey resets it only with pool_smart_discard=yes (off by default). Threat: the next client reads data through the previous client's settings, silent data corruption | ✗ | ✓ | ✓ |
| [0142](features/session-state/0142-pcsp-bug-3-parse-error-does/steps.feature) re-Parse of the same name after a failed Parse: pgbouncer disconnects the client with "prepared statement name is already in use" ([pgbouncer#1630](https://github.com/pgbouncer/pgbouncer/issues/1630)). Threat: a legal driver retry kills the session | ✓ | ✗ | ✓ |
| [0173](features/session-state/0173-dcc-deallocate-specific-statement-clears-only/steps.feature) DEALLOCATE by name through a SimpleQuery: pgbouncer answers 26000 and disconnects, it maps only DEALLOCATE ALL and DISCARD ALL (src/server.c). Threat: session dies on a plain DEALLOCATE. Note: pg_doorman answers CommandComplete but leaks the server-side statement | ✓ | ✗ | ✓ |
| [0226](features/lang-compiled/0226-run-net-multi-session-tests/steps.feature) Npgsql, 5 parallel connections with 20 prepared executes each: pgbouncer loses mapped statements under concurrency, FATAL 08P01 "prepared statement did not exist". Threat: prepared queries of random clients start failing | ✓ | ✗ | ✓ |
| [0248](features/lang-jvm-script/0248-run-java-aggressive-mixed-tests-batch-prepared-statements-ex/steps.feature) pgjdbc batch INSERT with an expected 23505, then ROLLBACK: odyssey drops its name mapping on the error, the retry Bind reaches the server unmapped and dies 26000 before ROLLBACK runs, the next round hits the duplicate key. Threat: no transaction recovery after a batch error | ✗ | ✓ | ✓ |
| [0254](features/lang-jvm-script/0254-run-python-session-cursors-tests/steps.feature) psycopg2 CURSOR WITH HOLD: the cursor outlives its client and becomes visible to the NEXT client. Direct PG destroys it at session end. Both projects document "no session features" but not the cross-client visibility ([pgbouncer#976](https://github.com/pgbouncer/pgbouncer/issues/976)). Threat: session objects leak between clients | ✗ | ✗ | ✓ |

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
                   session-state, crash, lang-compiled, lang-jvm-script
testkit/harness/   cucumber harness (Rust)
testkit/drivers/   driver test sources: go, java, dotnet, python, nodejs, php
testkit/configs/   base pooler config profiles (+ certs/)
testkit/fixtures/  shared SQL fixtures
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
