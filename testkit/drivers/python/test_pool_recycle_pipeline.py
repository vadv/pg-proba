import os
import sys

import psycopg

# Life pattern: pooled connector reset + re-prepare in one pipelined
# batch — what Npgsql does on connector reuse and what psycopg3 apps
# do in pipeline mode (https://www.psycopg.org/psycopg3/docs/advanced/pipeline.html).
# Direct PG: DISCARD ALL deallocates only statements prepared before it;
# the fresh Parse in the same batch is valid. A transaction pooler must
# not apply the DISCARD retroactively to that Parse's mapping.

url = os.getenv("DATABASE_URL") or "postgresql://example_user_1:test@127.0.0.1:6432/example_db"

try:
    with psycopg.connect(url, autocommit=True, sslmode="disable") as conn:
        cur = conn.cursor()

        # app uses a real protocol-level prepared statement
        cur.execute("SELECT %s::int + %s::int", (7, 35), prepare=True)
        if cur.fetchone()[0] != 42:
            sys.exit("FAIL: prepared query returned wrong result")

        # connector recycled: session reset + fresh re-prepare pipelined
        with conn.pipeline():
            cur.execute("DISCARD ALL")
            cur.execute("SELECT %s::int - %s::int", (50, 8), prepare=True)
        if cur.fetchone()[0] != 42:
            sys.exit("FAIL: re-prepared query returned wrong result")
except Exception as e:
    sys.exit(f"FAIL: {type(e).__name__}: {e}")

print("PASS: pipelined DISCARD ALL + re-prepare survives (42 twice)")
