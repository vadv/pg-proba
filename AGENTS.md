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

The corpus comes from the pg_doorman BDD suite (MIT). Upstream scenarios
bundle many checks into one; here one test = one behavior, so the corpus is
split into atomic tests. The 183 upstream scenarios are heritage, not the
test count.

## Working rules

- Any tool is allowed. The requirement is transparency: a person reading
  this repo can always tell what runs, with which config, and what is expected.
- Docs and tests in English.
- Never soften an expectation to make a pooler pass — the runner is the proof.
