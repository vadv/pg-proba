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

Explicitly skipped (harness owns the process; slice 1 of the integration):
- runtime config changes: bouncer.write_ini(), bouncer.run_with_config()
- log inspection: bouncer.log_contains(), bouncer.print_logs()
- network fault injection: pg.drop_traffic()/reject_traffic()/add_latency()
- PostgreSQL lifecycle: pg.restart()/arestart()/stop()/reload()/delayed_start()/configure()
"""

import os
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
        self.ini_path = self.config_dir / "pgbouncer-upstream-unused.ini"
        self.log_path = self.config_dir / "pgbouncer-upstream-unused.log"
        # Admin console over TCP (unix_socket_dir is empty in our configs).
        self.admin_host = "127.0.0.1"
        self.admin_runner = QueryRunner("127.0.0.1", int(os.environ["POOLER_PORT"]))
        self.admin_runner.default_db = "pgbouncer"
        self.admin_runner.default_user = "pgbouncer"
        self.admin_runner.default_password = "fake"

    # -- runtime config / logs: harness-owned process, skip cleanly ------
    def write_ini(self, config):
        _skip("bouncer.write_ini()")

    def run_with_config(self, config):
        _skip("bouncer.run_with_config()")

    def log_contains(self, re_string, times=None):
        _skip("bouncer.log_contains()")

    def print_logs(self):
        print("(pooler log goes to the harness stdout; no log file in this adapter)")


@pytest.fixture(scope="session")
def pg():
    return HarnessPostgres()


@pytest.fixture
def bouncer(pg):
    if os.environ.get("POOLER", "pgbouncer") != "pgbouncer":
        pytest.skip("upstream suite is wired for pgbouncer only (slice 1)")
    return HarnessBouncer(pg)
