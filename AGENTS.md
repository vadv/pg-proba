# pooler-index

A public index of PostgreSQL connection poolers.

The message: **transparency of tests.** There is a large corpus of protocol
tests. Each pooler runs the same corpus, in the same repeatable conditions.
The score is simple: the percentage of tests passed.

Direct PostgreSQL is the oracle: the same corpus against a direct connection
must give 100%. Every test a pooler fails is a place where the client can
tell it is not talking to PostgreSQL.

## What a reader must see

- **The test text.** A test reads like: "Start the pooler with this config,
  pointing at PostgreSQL with that config. Send this. Expect that."
  A reader who never runs anything still understands every test.
- **The config.** The config a pooler actually ran with is part of the result.
- **The score.** passed / total, no weights.
- **Results in the README:** intro, the leaderboard, then the per-test table —
  test text, pass/fail for pg_doorman / Odyssey / PgBouncer, link to the test.

## Corpus

Two sources:

- The pg_doorman BDD suite (MIT). Upstream scenarios bundle many checks into
  one; here one test = one behavior, so the corpus is split into atomic tests.
  The 183 upstream scenarios are heritage, not the test count.
- The upstream PgBouncer python suite (ISC, vendored at
  `testkit/upstream/pgbouncer/`, tag `pgbouncer_1_26_1`), one pytest node per
  feature. Runtime setup that upstream does via the admin console
  (`SET`/`RELOAD`) is moved into static per-case config profiles rendered by
  `testkit/upstream/generate.py` from the triage table `testkit/upstream/cases.tsv`.
  Every node declares per-pooler capability — `supported`, `unsupported:` (by
  design), `unadapted:` (no workaround yet) — with a mandatory reason; the
  harness reports N/A / UNADAPTED before starting services and never as PASS.
  Where a pooler legitimately differs by design (e.g. pg_doorman keeps serving
  prepared statements across a client DISCARD ALL), the case is scored N/A for
  that pooler — the expectation itself is never softened.

## Working rules

- Any tool is allowed. The requirement is transparency: a person reading
  this repo can always tell what runs, with which config, and what is expected.
- Docs and tests in English.
- Never soften an expectation to make a pooler pass — the runner is the proof.
