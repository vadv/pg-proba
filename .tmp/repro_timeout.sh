#!/bin/bash
# Repro: test_timeouts.py::test_query_wait_timeout[2-None-None] against a manually
# started pgbouncer (as postgres user, like the harness), log fully visible.
set -uxo pipefail
cd /workspace/testkit/upstream/pgbouncer

rm -rf /tmp/repro-pg /tmp/repro-pb.log /tmp/repro-pb.ini /tmp/repro-userlist

sudo -u postgres initdb -D /tmp/repro-pg >/dev/null
echo 'local all all trust
host all all 127.0.0.1/32 trust' > /tmp/repro-pg/pg_hba.conf
sudo -u postgres pg_ctl -D /tmp/repro-pg -l /tmp/repro-pg.log -o "-p 15432 -k /tmp" start
for db in p0 p1 p2 p3 p3x p9 postgres; do sudo -u postgres createdb -p 15432 "$db" 2>/dev/null || true; done
for u in bouncer puser1 puser2 puser3 stats pgbouncer; do sudo -u postgres createuser -p 15432 "$u" 2>/dev/null || true; done

cat > /tmp/repro-pb.ini <<'EOF'
[databases]
p0 = host=127.0.0.1 port=15432 dbname=p0
p1 = host=127.0.0.1 port=15432 dbname=p1
p2 = host=127.0.0.1 port=15432 dbname=p0
p3 = host=127.0.0.1 port=15432 dbname=p0
p3x = host=127.0.0.1 port=15432 dbname=p0
p9 = host=127.0.0.1 port=15432 dbname=p0
non_existing_pg_db = host=127.0.0.1 port=15432 dbname=non_existing_pg_db

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 16667
unix_socket_dir =
admin_users = pgbouncer
stats_users = stats
auth_type = trust
auth_file = /tmp/repro-userlist
pool_mode = transaction
max_prepared_statements = 200
logfile = /tmp/repro-pb.log
EOF
printf '"bouncer" ""\n"puser1" "foo"\n"puser2" "foo"\n"puser3" "foo"\n"stats" "foo"\n"pgbouncer" "fake"\n' > /tmp/repro-userlist
chmod 644 /tmp/repro-pb.ini /tmp/repro-userlist

sudo -u postgres pgbouncer -d /tmp/repro-pb.ini
sleep 1

export POOLER=pgbouncer POOLER_PORT=16667 PG_PORT=15432
export PGBOUNCER_INI=/tmp/repro-pb.ini PGBOUNCER_LOG=/tmp/repro-pb.log PGBOUNCER_USERLIST=/tmp/repro-userlist
python3 -m pytest -q "test_timeouts.py::test_query_wait_timeout[2-None-None]" -o asyncio_mode=auto --timeout=120 -p no:cacheprovider; rc=$?

echo "=== pytest rc=$rc ==="
sudo -u postgres pg_ctl -D /tmp/repro-pg stop || true
sudo -u postgres pgbouncer -u pgbouncer -d /tmp/repro-pb.ini -R 2>/dev/null || true
echo "=== pgbouncer log tail ==="
tail -50 /tmp/repro-pb.log
echo "=== pgbouncer still running? ==="
pgrep -a pgbouncer || echo "pgbouncer is DEAD"
exit 0
