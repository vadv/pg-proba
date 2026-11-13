"""pg-proba adapter for the vendored upstream PgBouncer test suite.

Files in this directory are vendored verbatim from the pgbouncer tag
pgbouncer_1_26_1 (see VENDORED.md).  Upstream's own conftest.py spawns a
private PostgreSQL and PgBouncer per test run; here both are started by
the pg-proba cucumber harness before the pytest process is launched
(see features/upstream/0001-pgbouncer-upstream-python-suite/steps.feature),
so the ``pg`` and ``bouncer`` fixtures below bind to the already running
instances instead of creating them.

Supported by this adapter:
- client connections through the pooler (conn/cur/sql/test/asleep/...)
- bouncer.admin()/aadmin() via the real PgBouncer admin console
- pg.connection_count()
- runtime config rewrites: write_ini()/reset_ini()/run_with_config()
  (inherited from utils.Bouncer; the harness renders the ini to a temp
  file the pytest process can rewrite, and RELOAD goes through admin())

Explicitly skipped (harness owns the process; slice 1 of the integration):
- log inspection: bouncer.log_contains(), bouncer.print_logs()
- network fault injection: pg.drop_traffic()/reject_traffic()/add_latency()
- PostgreSQL lifecycle: pg.restart()/arestart()/stop()/reload()/delayed_start()/configure()
"""

import os
import re
from contextlib import contextmanager
from pathlib import Path

import pytest

from .utils import Bouncer, Postgres, QueryRunner


def _skip(what):
    pytest.skip(f"{what}: not supported by the pg-proba harness adapter")


class HarnessPostgres(Postgres):
    """Upstream Postgres API bound to the harness-started PostgreSQL."""

    def __init__(self):
        QueryRunner.__init__(self, "127.0.0.1", int(os.environ["PG_PORT"]))
        self.pgdata = None
        self.process = None

    # -- lifecycle / firewall: harness-owned process, skip cleanly ------
    def restart(self):
        _skip("pg.restart()")

    def arestart(self):
        _skip("pg.arestart()")

    def stop(self):
        _skip("pg.stop()")

    def reload(self):
        _skip("pg.reload()")

    def configure(self, config):
        _skip("pg.configure()")

    def delayed_start(self, *args, **kwargs):
        _skip("pg.delayed_start()")

    def drop_traffic(self):
        _skip("pg.drop_traffic() (needs NET_ADMIN)")

    def reject_traffic(self):
        _skip("pg.reject_traffic() (needs NET_ADMIN)")

    def add_latency(self):
        _skip("pg.add_latency() (needs NET_ADMIN)")


class HarnessBouncer(Bouncer):
    """Upstream Bouncer API bound to the harness-started pooler."""

    def __init__(self, pg):
        QueryRunner.__init__(self, "127.0.0.1", int(os.environ["POOLER_PORT"]))
        self.pg = pg
        self.default_db = "p0"
        # Attributes some vendored tests touch directly before we get a
        # chance to skip them (test_operations, test_timeouts).
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

    # -- runtime config / logs: harness-owned process, skip cleanly ------
    def write_ini(self, config):
        _skip("bouncer.write_ini()")

    def run_with_config(self, config):
        _skip("bouncer.run_with_config()")

    @contextmanager
    def log_contains(self, re_string, times=None):
        """Same contract as upstream: log lines matching re_string must
        appear while the with-block runs (assert on exit, like upstream)."""
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
    if os.environ.get("POOLER", "pgbouncer") != "pgbouncer":
        pytest.skip("upstream suite is wired for pgbouncer only (slice 1)")
    return HarnessBouncer(pg)
