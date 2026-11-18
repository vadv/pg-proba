"""Dependency-free checks: python3 -m unittest discover -s testkit/upstream -p test_adapter.py."""
import ast
import base64
import hashlib
import hmac
import configparser
import importlib.util
import os
import re
import shlex
import shutil
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock

import generate

spec = importlib.util.spec_from_file_location("results", Path(__file__).parent / "pgbouncer/results.py")
results = importlib.util.module_from_spec(spec)
spec.loader.exec_module(results)


class AdapterTests(unittest.TestCase):
    def test_native_profiles(self):
        for name, settings in generate.PROFILES.items():
            targets = generate.profile_poolers(name)
            self.assertTrue(targets, name)
            for pooler in targets:
                with self.subTest(profile=name, pooler=pooler):
                    text = generate.render(generate.POOLERS[pooler], name)
                    cache = settings.get("cache", 200)
                    if pooler == "pgbouncer":
                        config = configparser.ConfigParser(interpolation=None)
                        config.read_string(text)
                        self.assertEqual(config.getint("pgbouncer", "max_prepared_statements"), cache)
                        self.assertEqual(config.getint("pgbouncer", "server_idle_timeout"), settings.get("idle", 60))
                        self.assertEqual(config["pgbouncer"]["auth_type"], settings.get("auth", "trust"))
                    elif pooler == "odyssey":
                        self.assertEqual(set(re.findall(r"server_pstmt_cache_size (\d+)", text)), {str(cache)})
                        self.assertIn("server_lifetime 2\n", text)
                        self.assertNotIn("server_ttl", text)
                        self.assertEqual(text.count("client_fwd_error yes"), text.count('storage "pg0"\n'))
                        self.assertIn("pool_reserve_prepared_statement yes", text)
                        self.assertNotRegex(text, r"(?m)^\s+reserve_prepared_statement")
                        self.assertIn(f"pool_ttl {settings.get('idle', 60)}\n", text)
                        if "auth" in settings:
                            self.assertIn('user "postgres" {', text)
                    else:
                        dm = tomllib.loads(re.sub(r"\$\{\w+\}", "15432", text))
                        self.assertEqual(dm["general"]["server_prepared_statements_cache_size"], cache)
                        self.assertEqual(dm["general"]["idle_timeout"], settings.get("idle", 60) * 1000)
                        self.assertEqual(dm["general"]["server_lifetime"], settings.get("lifetime", 120) * 1000)
                        self.assertEqual(dm["general"]["query_wait_timeout"], settings.get("wait", 5) * 1000)
                        self.assertTrue(dm["general"]["sync_server_parameters"])
                        self.assertEqual(dm["general"]["retain_connections_time"], 100)
                        self.assertEqual(dm["pools"]["p9"]["server_lifetime"], 2000)
                        for pool in ("p0", "p3", "p3x", "p9"):
                            self.assertEqual(dm["pools"][pool]["server_database"], "p0")
                            self.assertTrue(all(u["server_username"] == "bouncer" for u in dm["pools"][pool]["users"]))
                        for pool in ("p1", "p3x"):
                            self.assertTrue(all(u["pool_size"] == settings.get("size", 5) for u in dm["pools"][pool]["users"]))
                        self.assertTrue(all("prepared_statements" not in p for p in dm["pools"].values()))
                        if "auth" in settings:
                            self.assertTrue(dm["general"]["pg_hba"]["content"].endswith(settings["auth"]))
                            for pool in ("p1", "p2"):
                                user = next(u for u in dm["pools"][pool]["users"] if u["username"] == "postgres")
                                self.assertEqual(user["password"], generate.POSTGRES_PASSWORDS[settings["auth"]])

    def test_control_password_verifiers(self):
        self.assertEqual(generate.POSTGRES_PASSWORDS["trust"], "")
        self.assertEqual(generate.POSTGRES_PASSWORDS["md5"], "md5" + hashlib.md5(b"asdasdpostgres").hexdigest())
        method, salt_spec, keys = generate.POSTGRES_PASSWORDS["scram-sha-256"].split("$")
        self.assertEqual(method, "SCRAM-SHA-256")
        iterations, salt = salt_spec.split(":")
        key = hashlib.pbkdf2_hmac("sha256", b"asdasd", base64.b64decode(salt), int(iterations))
        stored, server = map(base64.b64decode, keys.split(":"))
        self.assertEqual(stored, hashlib.sha256(hmac.digest(key, b"Client Key", "sha256")).digest())
        self.assertEqual(server, hmac.digest(key, b"Server Key", "sha256"))

    def test_auth_query_profiles(self):
        for name in ("auth-query", "auth-query-null"):
            dm = tomllib.loads(re.sub(r"\$\{\w+\}", "15432", generate.render("pg_doorman.toml", name)))
            query = dm["pools"]["authdb"]["auth_query"]["query"]
            self.assertIn(query, generate.render("pgbouncer.ini", name))
            self.assertIn(query, generate.render("odyssey.conf", name))
            self.assertEqual(query.startswith("SELECT (SELECT"), name.endswith("-null"))
            if name.endswith("-null"):
                self.assertIn(" AS passwd", query)
            self.assertIn('authentication "scram-sha-256"\n    auth_query', generate.render("odyssey.conf", name))
            self.assertEqual(dm["pools"]["authdb"]["auth_query"]["server_user"], "bouncer")

    def test_selected_nodes_have_no_unadapted_calls(self):
        console = {"admin", "aadmin", "run_with_config", "log_contains", "write_ini", "reset_ini"}
        network = {"drop_traffic", "add_latency", "reject_traffic"}
        entries = generate.cases()
        self.assertEqual(len(entries), len({r["node"] for r in entries}))
        for row in entries:
            file, node = row["node"].split("::")
            functions = {n.name: n for n in ast.parse((Path(__file__).parent / "pgbouncer" / file).read_text()).body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
            function = functions[node.split("[")[0]]
            if not any(row[p] == "supported" for p in generate.POOLERS):
                self.assertTrue(row["reason"], row["node"])
                continue
            with self.subTest(node=row["node"]):
                calls = {n.func.attr for n in ast.walk(function) if isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)}
                targets = {p for p in generate.POOLERS if row[p] == "supported"}
                forbidden = set() if targets == {"pgbouncer"} else console
                self.assertFalse(calls & forbidden)
                self.assertEqual(bool(calls & network), row["resources"] == "network")
                feature = generate.feature(row)
                if row["resources"] == "network":
                    self.assertIn('@network\n', feature)
                    self.assertIn('bash ../run_network.sh', feature)
                    feature = (Path(__file__).parent / "run_network.sh").read_text()
                self.assertIn('--timeout-method=thread', feature)
                self.assertIn('timeout --kill-after=5s 70s', feature)
                self.assertEqual(feature.count('python3 -m pytest'), 1)

    def test_target_capabilities_are_explicit(self):
        for row in generate.cases():
            for pooler in generate.POOLERS:
                status = row[pooler].split(":")[0]
                self.assertIn(status, ("supported", "unsupported", "unadapted"))
                if status != "supported":
                    self.assertTrue(row[pooler].split(": ", 1)[1].strip())
                self.assertIn(f"@{status}-{pooler}", generate.feature(row))
        plain = next(r for r in generate.cases() if r["node"] == "test_no_user.py::test_no_user_password")
        self.assertEqual(generate.profile_poolers("auth-plain"), {"pgbouncer", "odyssey"})
        self.assertTrue(plain["pg_doorman"].startswith("unsupported: "))
        self.assertIn('authentication "clear_text"', generate.render("odyssey.conf", "auth-plain"))

    def test_wildcard_routes_do_not_alias_the_database(self):
        self.assertEqual(generate.profile_poolers("wildcard"), {"pgbouncer", "odyssey"})
        pb = configparser.ConfigParser(interpolation=None)
        pb.read_string(generate.render("pgbouncer.ini", "wildcard"))
        self.assertIn("*", pb["databases"])
        self.assertNotIn("dbname=", pb["databases"]["*"])
        odyssey = generate.render("odyssey.conf", "wildcard").split("database default {")[1]
        self.assertNotIn("storage_db", odyssey)
        with self.assertRaises(ValueError):
            generate.render("pg_doorman.toml", "wildcard")

    def test_client_timers_do_not_set_backend_idle(self):
        for profile, pb_key, od_key in (
            ("client-idle-2", "client_idle_timeout", "pool_client_idle_timeout"),
            ("transaction-idle-2", "idle_transaction_timeout", "pool_idle_in_transaction_timeout"),
        ):
            targets = {"pgbouncer"} if profile == "client-idle-2" else {"pgbouncer", "odyssey"}
            self.assertEqual(generate.profile_poolers(profile), targets)
            config = configparser.ConfigParser(interpolation=None)
            config.read_string(generate.render("pgbouncer.ini", profile))
            self.assertEqual(config.getint("pgbouncer", pb_key), 2)
            self.assertEqual(config.getint("pgbouncer", "server_idle_timeout"), 60)
            if "odyssey" in targets:
                odyssey = generate.render("odyssey.conf", profile)
                self.assertIn("virtual_transaction no", odyssey)
                self.assertEqual(set(re.findall(r"(?m)^\s*" + od_key + r" (\d+)$", odyssey)), {"2"})
                self.assertEqual(set(re.findall(r"pool_ttl (\d+)", odyssey)), {"60"})
        self.assertNotIn("virtual_transaction no", generate.render("odyssey.conf", "default"))

    def test_idle_timeout_messages(self):
        source = (Path(__file__).parent / "pgbouncer/test_timeouts.py").read_text()
        function = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == "test_idle_transaction_timeout")
        raises = next(n for n in ast.walk(function) if isinstance(n, ast.Call) and ast.unparse(n.func) == "pytest.raises")
        pattern = next(k.value.value for k in raises.keywords if k.arg == "match")
        self.assertRegex("idle transaction timeout", pattern)
        self.assertRegex("Connection was dropped by Odyssey due to idle in transaction timeout", pattern)
        self.assertNotRegex("query_wait_timeout", pattern)
        self.assertNotRegex("connection refused", pattern)

    def test_postgres_control_preserves_harness_options(self):
        # Load the stdlib adapter without importing the vendored psycopg dependency.
        source = ast.parse((Path(__file__).parent / "pgbouncer/conftest.py").read_text())
        cls = next(n for n in source.body if isinstance(n, ast.ClassDef) and n.name == "HarnessPostgres")
        method = next(n for n in cls.body if isinstance(n, ast.FunctionDef) and n.name == "pgctl")
        run = Mock()
        ns = {"shlex": shlex, "subprocess": SimpleNamespace(run=run)}
        exec(compile(ast.Module(body=[method], type_ignores=[]), "conftest.py", "exec"), ns)
        pg = SimpleNamespace(pgdata=Path("/tmp/pg data/db"), start_options='-D "/tmp/pg data/db" -p 1234 -F -k "/tmp/pg data"')
        for uid in (0, 1000):
            ns["os"] = SimpleNamespace(geteuid=lambda: uid)
            ns["pgctl"](pg, '-o "-p 1234" -l "/tmp/pg log" start')
            args = run.call_args.args[0]
            self.assertEqual(args[:3], ["sudo", "-u", "postgres"] if uid == 0 else ["pg_ctl", "-w", "-t"])
            self.assertEqual(args[args.index("-o") + 1], pg.start_options)
            self.assertEqual(args[args.index("--pgdata") + 1], str(pg.pgdata))
            self.assertEqual(args[-2:], ["/tmp/pg log", "start"])
            self.assertEqual(run.call_args.kwargs, {"check": True, "timeout": 15})
        ns["pgctl"](pg, "-m fast stop", check=False)
        self.assertFalse(run.call_args.kwargs["check"])

    def test_network_cleanup_preserves_exit_status(self):
        script = Path(__file__).parent / "run_network.sh"
        self.assertIn("USE_SUDO=1 timeout", script.read_text())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("tc", "iptables", "timeout"):
                tool = root / name
                tool.write_text('#!/bin/sh\nname=${0##*/}\nprintf "%s %s\\n" "$name" "$*" >> "$CALLS"\n[ "$name" != timeout ] || exit "$RESULT"\nif [ "$name" = tc ] && [ "$2" = del ] && [ "$FAIL_CLEANUP" = 1 ]; then exit 1; fi\n')
                tool.chmod(0o755)
            for code, fail_cleanup in ((0, 0), (7, 0), (124, 0), (137, 0), (0, 1)):
                log = root / "calls"
                log.write_text("")
                env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}", CALLS=str(log), RESULT=str(code), FAIL_CLEANUP=str(fail_cleanup), PG_PORT="55432")
                result = subprocess.run(["bash", str(script), "test_prepared.py::test_prepared_statement_pipeline_latency"], env=env, capture_output=True, timeout=10)
                self.assertEqual(result.returncode, code or fail_cleanup, result.stderr)
                calls = log.read_text()
                self.assertIn("tc qdisc del dev lo root", calls)
                self.assertEqual(calls.count("iptables -D OUTPUT"), 2)
                self.assertIn("--dport 55432", calls)

    def test_nested_discovery_and_network_privileges(self):
        source = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "env").mkdir()
            for name in ("run.sh", "test-result.sh"):
                shutil.copyfile(source / "env" / name, root / "env" / name)
            for name in ("flake.nix", "flake.lock"):
                (root / "env" / name).touch()
            for path, tag in (("features/protocol/example/steps.feature", "@protocol"), ("features/upstream/suite/case/steps.feature", "@network")):
                feature = root / path
                feature.parent.mkdir(parents=True)
                feature.write_text(tag + "\nFeature: check\n")
            docker = root / "docker"
            docker.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$CALLS"\n[ "$1" != run ] || echo "1 scenario (1 passed)"\nexit 0\n')
            docker.chmod(0o755)
            log = root / "calls"
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}", CALLS=str(log))
            result = subprocess.run(["bash", str(root / "env/run.sh"), "matrix"], env=env, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            calls = [line for line in log.read_text().splitlines() if line.startswith("run ")]
            self.assertEqual(len(calls), 6)
            for line in calls:
                self.assertEqual("--cap-add=NET_ADMIN" in line, "features/upstream/" in line)
                self.assertNotIn("--privileged", line)
                self.assertNotIn("--network=host", line)

    def test_pause_keeps_upstream_wait_budget(self):
        row = next(r for r in generate.cases() if r["node"] == "test_operations.py::test_pause_resume")
        config = configparser.ConfigParser(interpolation=None)
        config.read_string(generate.render("pgbouncer.ini", row["profile"]))
        self.assertEqual(config.getint("pgbouncer", "query_wait_timeout"), 120)

    def test_setup_specific_profiles(self):
        profiles = {r["node"].split("::")[1]: r["profile"] for r in generate.cases()}
        self.assertEqual(profiles['test_evict_statement_cache_pipeline_failure'], 'cache-1')
        self.assertEqual(profiles['test_close_batched_with_evicting_parse'], 'cache-1')
        self.assertEqual(profiles['test_prepared_statement_pipeline_stress'], 'cache-66')
        self.assertEqual(profiles['test_cancel_race'], 'single-idle-2')

    def test_feature_result_classification(self):
        for code, output, expected in [
            (0, "1 scenario (1 passed)\n", "PASS"),
            (0, "3 scenarios (3 passed)\n", "PASS"),
            (1, "1 scenario (1 failed)\n", "FAIL"),
            (0, "UPSTREAM_NA pg_doorman: unsupported method\n", "N/A"),
            (0, "UPSTREAM_UNADAPTED odyssey: missing setup\n", "UNADAPTED"),
            (1, "UPSTREAM_NA pg_doorman: unsupported method\n", "FAIL"),
            (0, "0 scenarios\n", "FAIL"),
            (0, "", "FAIL"),
        ]:
            with self.subTest(code=code, output=output):
                run = subprocess.run(["bash", str(generate.ROOT / "env/test-result.sh"), str(code)], input=output, text=True, capture_output=True, check=True)
                self.assertEqual(run.stdout.strip(), expected)

    def test_skips_and_empty_selections_are_not_success(self):
        for stats, collected, initial, expected in [
            ({"passed": [1]}, 1, 0, 0),
            ({"skipped": [1]}, 1, 0, 1),
            ({"passed": [1], "skipped": [2]}, 2, 0, 1),
            ({"xfailed": [1]}, 1, 0, 1),
            ({}, 0, 0, 1),
            ({"failed": [1]}, 1, 1, 1),
            ({"error": [1]}, 1, 1, 1),
        ]:
            with self.subTest(stats=stats):
                lines = []
                reporter = SimpleNamespace(stats=stats, write_line=lines.append)
                session = SimpleNamespace(config=SimpleNamespace(pluginmanager=SimpleNamespace(get_plugin=lambda _: reporter)), testscollected=collected, exitstatus=initial)
                results.pytest_sessionfinish(session, initial)
                self.assertEqual(session.exitstatus, expected)
                self.assertIn("UPSTREAM_RESULT", lines[0])


if __name__ == "__main__":
    unittest.main()
