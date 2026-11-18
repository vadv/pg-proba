#!/usr/bin/env bash
# Keep faults scoped to this backend and clean up even when pytest is killed.
set -euo pipefail
cd "$(dirname "$0")/pgbouncer"
: "${PG_PORT:?PG_PORT is required}"
command -v tc iptables timeout python3 >/dev/null
qdisc_created=0
cleanup() {
  local code=$?
  trap - EXIT
  for action in DROP REJECT; do
    rule=(-p tcp -d 127.0.0.1 --dport "$PG_PORT" -j "$action")
    [ "$action" != REJECT ] || rule+=(--reject-with tcp-reset)
    if iptables -C OUTPUT "${rule[@]}" 2>/dev/null; then
      iptables -D OUTPUT "${rule[@]}" || code=1
    fi
  done
  if [ "$qdisc_created" = 1 ]; then
    tc qdisc del dev lo root || code=1
  fi
  exit "$code"
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# Normal packets use band 1; upstream's port filter selects delayed band 2.
tc qdisc add dev lo root handle 1: prio bands 3 priomap 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
qdisc_created=1
tc qdisc add dev lo parent 1:2 handle 20: netem delay 1000ms
USE_SUDO=1 timeout --kill-after=5s 70s python3 -m pytest -q "$1" -o asyncio_mode=auto --timeout=45 --timeout-method=thread -p no:cacheprovider
