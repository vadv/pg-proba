"""pg-proba adapter for the vendored upstream PgBouncer test suite.

Tests originate from tag pgbouncer_1_26_1 (upstream: test/) and are adapted
for the common data-plane corpus. Native/unadapted cases are listed separately
in ../cases.tsv; setup-only settings live in generated native profiles.  Upstream's
own conftest.py spawns a private PostgreSQL and PgBouncer per test run;
here both are started by the pg-proba cucumber harness before the pytest
process is launched (see features/upstream/0001-pgbouncer-upstream-python-suite/),
so the ``pg`` and ``bouncer`` fixtures below bind to the already running
instances instead of creating them.

Supported by this adapter:
- client connections through the pooler (conn/cur/sql/test/asleep/...)
- bouncer.admin()/aadmin() via the admin console (PgBouncer SQL console;
  pg_doorman accepts the same "pgbouncer" admin database)
- pg.connection_count() and PostgreSQL lifecycle via the harness data directory
- runtime config rewrites: write_ini()/reset_ini()/run_with_config()
  (inherited from utils.Bouncer; the harness renders the config to a
  real file the pytest process can rewrite, and RELOAD goes through
  admin()) - PgBouncer only, guarded on POOLER
- log inspection: bouncer.log_contains()/print_logs() against the
  harness-exposed log file

Network fault injection uses upstream methods inside run_network.sh, which
provides isolated firewall/tc setup and cleanup even after a pytest timeout.
"""

import asyncio
import os
import re
import shlex
import subprocess
from contextlib import contextmanager
from pathlib import Path

import pytest

from .utils import Bouncer, Postgres, QueryRunner
from .results import pytest_sessionfinish


def _unsupported(what):
    pytest.fail(f"Unadapted operation reached a selected test: {what}")


class HarnessPostgres(Postgres):
    """Upstream Postgres API bound to the harness-started PostgreSQL."""

    def __init__(self):
        QueryRunner.__init__(self, "127.0.0.1", int(os.environ["PG_PORT"]))
        self.pgdata = Path(self.sql_value("show data_directory"))
        self.log_path = self.pgdata.parent / "pg.log"
        self.start_options = shlex.join(shlex.split((self.pgdata / "postmaster.opts").read_text())[1:])

    def pgctl(self, command, **kwargs):
        args = shlex.split(command)
        if args[-1] == "start" and "-o" in args:
            # Upstream supplies only the port; retain the harness's other startup options.
            args[args.index("-o") + 1] = self.start_options
        args = ["pg_ctl", "-w", "-t", "10", "--pgdata", str(self.pgdata), *args]
        if os.geteuid() == 0:
            args = ["sudo", "-u", "postgres", *args]
        kwargs.setdefault("check", True)
        kwargs.setdefault("timeout", 15)
        return subprocess.run(args, **kwargs)

    async def arestart(self):
        await asyncio.to_thread(self.pgctl, "-m fast restart")


class HarnessBouncer(Bouncer):
    """Upstream Bouncer API bound to the harness-started pooler."""

    def __init__(self, pg):
        QueryRunner.__init__(self, "127.0.0.1", int(os.environ["POOLER_PORT"]))
        self.pg = pg
        self.default_db = "p0"
        # Attributes retained for native PgBouncer tests.
        self.config_dir = Path("/tmp")
        # The harness exports the real running config and log paths of the
        # pooler it started (see steps.feature: ${PGBOUNCER_CONFIG}/
        # ${PGBOUNCER_LOG}); tests that edit the ini and admin("reload") or
        # assert on log lines work against the real instance.
        self.ini_path = Path(os.environ.get("PGBOUNCER_INI", "/tmp/pgbouncer-upstream-unused.ini"))
        self.log_path = Path(os.environ.get("PGBOUNCER_LOG", "/tmp/pgbouncer-upstream-unused.log"))
        # Admin console over TCP (unix_socket_dir is empty in our configs).
        self.admin_host = "127.0.0.1"
        self.admin_runner = QueryRunner("127.0.0.1", int(os.environ["POOLER_PORT"]))
        self.admin_runner.default_db = "pgbouncer"
        self.admin_runner.default_user = "pgbouncer"
        self.admin_runner.default_password = "fake"
        self.auth_path = Path(
            os.environ.get(
                "PGBOUNCER_USERLIST",
                "/tmp/pgbouncer-upstream-unused.userlist",
            )
        )

    # -- runtime config / logs -----------------------------------------
    # write_ini/reset_ini/run_with_config are inherited from utils.Bouncer
    # and work against the real config file + admin RELOAD - but only on
    # poolers whose config is an ini (PgBouncer).
    def _require_ini_pooler(self, what):
        if os.environ.get("POOLER") != "pgbouncer":
            _unsupported(f"{what}: ini config rewrites only apply to PgBouncer")

    def write_ini(self, config):
        self._require_ini_pooler("bouncer.write_ini()")
        return super().write_ini(config)

    def reset_ini(self):
        self._require_ini_pooler("bouncer.reset_ini()")
        return super().reset_ini()

    def run_with_config(self, config):
        self._require_ini_pooler("bouncer.run_with_config()")
        return super().run_with_config(config)

    def admin(self, query, **kwargs):
        if os.environ.get("POOLER") != "pgbouncer":
            _unsupported("bouncer.admin(): runtime config via admin console is PgBouncer-only")
        return super().admin(query, **kwargs)

    def aadmin(self, query, **kwargs):
        if os.environ.get("POOLER") != "pgbouncer":
            _unsupported("bouncer.aadmin(): runtime config via admin console is PgBouncer-only")
        return super().aadmin(query, **kwargs)

    @contextmanager
    def log_contains(self, re_string, times=None):
        """Same contract as upstream: log lines matching re_string must
        appear while the with-block runs (assert on exit, like upstream)."""
        if os.environ.get("POOLER") != "pgbouncer":
            _unsupported("bouncer.log_contains(): log file only exposed for PgBouncer")
        with self.log_path.open() as f:
            f.seek(0, os.SEEK_END)
            yield
            content = f.read()
        if times is None:
            assert re.search(re_string, content), (
                f"pattern {re_string!r} not found in pooler log after the block; "
                f"tail: {content[-2000:]!r}"
            )
        else:
            match_count = len(re.findall(re_string, content))
            assert match_count == times, (
                f"pattern {re_string!r} matched {match_count} times, want {times}; "
                f"tail: {content[-2000:]!r}"
            )

    def print_logs(self):
        if os.environ.get("POOLER") != "pgbouncer":
            return
        try:
            tail = self.log_path.read_text()[-4000:]
            print(f"=== pooler log tail ({self.log_path}) ===\n{tail}")
        except OSError as e:
            print(f"(no pooler log at {self.log_path}: {e})")


def pytest_configure(config):
    # upstream marks used by the vendored files (avoids
    # PytestUnknownMarkWarning; upstream registers them in pytest.ini)
    config.addinivalue_line("markers", "md5: md5-specific fixture variant")


@pytest.fixture(scope="session")
def pg():
    return HarnessPostgres()


@pytest.fixture
def bouncer(pg):
    return HarnessBouncer(pg)
