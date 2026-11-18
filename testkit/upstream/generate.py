#!/usr/bin/env python3
"""Render per-case native setup; never emulate a PgBouncer admin response.

Run from any directory after changing cases.tsv or configs/upstream/.
Each case declares supported, unsupported or unadapted targets. The harness
reports unavailable targets before starting services, never as a test PASS.
"""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "testkit/configs/upstream"
FEATURES = ROOT / "features/upstream/0001-pgbouncer-upstream-python-suite"
POOLERS = {"pgbouncer": "pgbouncer.ini", "odyssey": "odyssey.conf", "pg_doorman": "pg_doorman.toml"}
# Doorman requires a verifier, not a cleartext password, even with HBA trust.
POSTGRES_PASSWORDS = {
    "trust": "",
    "md5": "md5bcf252a47ed6d557f25b020e3e9ac1f2",
    "scram-sha-256": "SCRAM-SHA-256$4096:cGctcHJvYmEtdXBzdHJlYW0=$Jag9mbqTVW5KM5af97T9x5F59Dp5gDlh4sCSopPwbKE=:CwdmP243eNG5ixC9aJnwttQs2gRwuHRTWaGnM+stBKU=",
}
PROFILES = {
    "default": {},
    "cache-1": {"cache": 1},
    "cache-66": {"cache": 66},
    "cache-100": {"cache": 100},
    "idle-2": {"idle": 2},
    "client-idle-2": {"client_idle": 2},
    "transaction-idle-2": {"transaction_idle": 2},
    "single-idle-2": {"size": 1, "idle": 2},
    "single-wait-5": {"size": 1},
    "lifetime-2": {"lifetime": 2},
    "wait-2": {"size": 1, "wait": 2},
    "wait-120": {"wait": 120},
    "auth-trust": {"auth": "trust"},
    "auth-plain": {"auth": "plain"},
    "auth-md5": {"auth": "md5"},
    "auth-scram": {"auth": "scram-sha-256"},
    "auth-query": {"auth": "md5", "auth_query": False},
    "auth-query-null": {"auth": "md5", "auth_query": True},
    "wildcard": {"wildcard": True},
}
# Explicit native names/units; unknown settings must not be silently ignored.
SETTINGS = {
    "pgbouncer.ini": {
        "wait": ("query_wait_timeout = 5", "query_wait_timeout = {}", 1),
        "cache": ("max_prepared_statements = 200", "max_prepared_statements = {}", 1),
        "idle": ("server_idle_timeout = 60", "server_idle_timeout = {}", 1),
        "client_idle": ("client_idle_timeout = 0", "client_idle_timeout = {}", 1),
        "transaction_idle": ("idle_transaction_timeout = 0", "idle_transaction_timeout = {}", 1),
        "size": ("default_pool_size = 5", "default_pool_size = {}", 1),
        "lifetime": ("server_lifetime = 120", "server_lifetime = {}", 1),
    },
    "pg_doorman.toml": {
        "wait": ("query_wait_timeout = 5000", "query_wait_timeout = {}", 1000),
        "cache": ("server_prepared_statements_cache_size = 200", "server_prepared_statements_cache_size = {}", 1),
        "idle": ("idle_timeout = 60000", "idle_timeout = {}", 1000),
        "size": ("pool_size = 5", "pool_size = {}", 1),
        "lifetime": ("server_lifetime = 120000", "server_lifetime = {}", 1000),
    },
    "odyssey.conf": {
        "wait": ("pool_timeout 5000", "pool_timeout {}", 1000),
        "cache": ("server_pstmt_cache_size 200", "server_pstmt_cache_size {}", 1),
        "idle": ("pool_ttl 60", "pool_ttl {}", 1),
        "transaction_idle": ("pool_idle_in_transaction_timeout 0", "pool_idle_in_transaction_timeout {}", 1),
        "size": ("pool_size 5", "pool_size {}", 1),
        "lifetime": ("server_lifetime 120", "server_lifetime {}", 1),
    },
}


def cases():
    with (ROOT / "testkit/upstream/cases.tsv").open() as f:
        return list(csv.DictReader(f, delimiter="\t"))


def profile_poolers(profile):
    return {p for row in cases() if row["profile"] == profile for p in POOLERS if row[p] == "supported"}


def auth_query_config(filename, null_row):
    query = (
        "SELECT (SELECT rolname FROM pg_authid WHERE rolname = $1) AS usename, "
        "(SELECT rolpassword FROM pg_authid WHERE rolname = $1) AS passwd"
        if null_row else "SELECT usename, passwd FROM pg_shadow WHERE usename = $1"
    )
    if filename == "pgbouncer.ini":
        return f"\nauth_query = {query}\n"
    if filename == "pg_doorman.toml":
        return f'''
[pools.authdb]
server_host = "127.0.0.1"
server_port = ${{PG_PORT}}
server_database = "p1"
server_tls_mode = "disable"
pool_mode = "transaction"
[pools.authdb.auth_query]
query = "{query}"
user = "pswcheck"
password = "pgbouncer-check"
database = "p1"
server_user = "bouncer"
server_password = ""
pool_size = 5
'''
    return f'''
database "auth_lookup" {{
  user "pswcheck" {{
    authentication "none"
    storage "pg0"
    client_fwd_error yes
    storage_db "p1"
    storage_user "pswcheck"
    pool "transaction"
    pool_size 1
    pool_routing "internal"
  }}
}}
database "authdb" {{
  user default {{
    authentication "scram-sha-256"
    auth_query "{query}"
    auth_query_db "auth_lookup"
    auth_query_user "pswcheck"
    storage "pg0"
    client_fwd_error yes
    storage_db "p1"
    storage_user "bouncer"
    pool "transaction"
    pool_size 5
  }}
}}
'''


def render(filename, profile):
    text = (BASE / filename).read_text()
    for key, value in PROFILES[profile].items():
        if key == "wildcard":
            if filename == "pgbouncer.ini":
                assert ";* = " in text
                text = text.replace(";* = ", "* = ")
            elif filename == "odyssey.conf":
                text += '''
database default {
  user default {
    authentication "none"
    client_fwd_error yes
    storage "pg0"
    pool "transaction"
    pool_size 5
    pool_reserve_prepared_statement yes
    server_pstmt_cache_size 200
    pool_ttl 60
    server_lifetime 120
    pool_timeout 5000
  }
}
'''
            else:
                raise ValueError("wildcard database routing is unavailable for this target")
            continue
        if key == "auth_query":
            text += auth_query_config(filename, value)
            continue
        if key == "auth":
            if filename == "pgbouncer.ini":
                text = text.replace("auth_type = trust", f"auth_type = {value}")
            elif filename == "pg_doorman.toml":
                text = text.replace("127.0.0.1/32 trust", f"127.0.0.1/32 {value}")
                text = re.sub(
                    r'(username = "postgres"\n(?:server_username = "bouncer"\n)?password = )""',
                    lambda match: match[1] + f'"{POSTGRES_PASSWORDS[value]}"',
                    text,
                )
            else:
                method = {"trust": "none", "plain": "clear_text"}.get(value, value)
                text = text.replace("user default {", 'user "postgres" {')
                text = text.replace('authentication "none"', f'authentication "{method}"\n    password "asdasd"')
            continue
        if key == "transaction_idle" and filename == "odyssey.conf":
            # The timeout needs an attached backend, not a virtual BEGIN.
            text = "virtual_transaction no\n" + text
        before, after, scale = SETTINGS[filename][key]
        assert before in text, (filename, profile, key)
        text = text.replace(before, after.format(value * scale))
    return "# Generated by testkit/upstream/generate.py; edit the base profile.\n" + text


def feature(row):
    node, profile = row["node"], row["profile"]
    tags = [f"@{row[p].split(':')[0]}-{p}" for p in POOLERS]
    capabilities = "\n  ".join(f"{p}: {row[p]}" for p in POOLERS)
    config = "testkit/configs/upstream" + (f"/{profile}" if profile != "default" else "")
    resource_tag = "@network\n" if row["resources"] == "network" else ""
    command = f'timeout --kill-after=5s 70s python3 -m pytest -q "{node}" -o asyncio_mode=auto --timeout=45 --timeout-method=thread -p no:cacheprovider'
    if row["resources"] == "network":
        command = f'bash ../run_network.sh "{node}"'
    return f'''@upstream
{resource_tag}{' '.join(tags)}
Feature: upstream {node}

  Adapted from PgBouncer 1.26.1. Native setup profile: {profile}.
  One pytest node, a fresh PostgreSQL and a fresh pooler per scenario.
  Required extra resources: {row["resources"]}.
  {capabilities}

  Background:
    Given PostgreSQL started with pg_hba.conf:
      """
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      """
    And fixtures from "testkit/fixtures/upstream_suite.sql" applied
    And pooler started with config from "{config}"

  Scenario: {node.split("::", 1)[1].replace("[", " (").replace("]", ")")}
    When I run shell command:
      """
      cd testkit/upstream/pgbouncer && POOLER_PORT=${{DOORMAN_PORT}} PG_PORT=${{PG_PORT}} PGBOUNCER_INI=${{PGBOUNCER_CONFIG}} PGBOUNCER_LOG=${{PGBOUNCER_LOG}} PGBOUNCER_USERLIST=${{PGBOUNCER_USERLIST}} {command}
      """
    Then the command should succeed
'''


def main():
    entries = cases()
    selected = [row for row in entries if any(row[p] == "supported" for p in POOLERS)]
    assert len({row["node"] for row in entries}) == len(entries)
    assert all(row["scope"] in ("common", "supported", "native", "unadapted") for row in entries)
    for row in entries:
        assert row["resources"] in ("none", "network"), row["node"]
        for p in POOLERS:
            assert row[p] == "supported" or row[p].startswith(("unsupported: ", "unadapted: ")), (row["node"], p)
            assert row[p] == "supported" or row[p].split(": ", 1)[1].strip(), (row["node"], p)
    for profile in {row["profile"] for row in selected} - {"default"}:
        target = BASE / profile
        target.mkdir(exist_ok=True)
        for pooler in profile_poolers(profile):
            filename = POOLERS[pooler]
            (target / filename).write_text(render(filename, profile))
        (target / "pgbouncer.userlist").write_text((BASE / "pgbouncer.userlist").read_text())
    for row in entries:
        directory = FEATURES / row["directory"]
        path = directory / "steps.feature"
        if row in selected:
            directory.mkdir(parents=True, exist_ok=True)
            path.write_text(feature(row))
        elif path.exists():
            path.unlink()
            if not any(directory.iterdir()):
                directory.rmdir()
    print(f"{len(selected)} scenarios runnable on at least one pooler; {len(entries) - len(selected)} unavailable on all poolers")
    for pooler in POOLERS:
        counts = {kind: sum(row[pooler].split(':')[0] == kind for row in entries) for kind in ('supported', 'unsupported', 'unadapted')}
        print(pooler, counts)


if __name__ == "__main__":
    main()
