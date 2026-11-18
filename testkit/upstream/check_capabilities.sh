#!/usr/bin/env bash
# End-to-end guard: the harness/CLI/reporters must never turn N/A into PASS.
set -euo pipefail
cd "$(dirname "$0")/../.."
logs=$(mktemp -d "${TMPDIR:-/tmp}/pg-proba-capabilities.XXXXXX")
trap 'rm -rf "$logs"' EXIT
features=features/upstream/0001-pgbouncer-upstream-python-suite

check_case() {
  local pooler=$1 directory=$2 expected=$3 code=0 result
  local log="$logs/$pooler-$directory.log"
  env/run.sh test "$pooler" "$features/$directory/steps.feature" >"$log" 2>&1 || code=$?
  result=$(bash env/test-result.sh "$code" <"$log")
  if [ "$result" != "$expected" ]; then
    tail -70 "$log"
    echo "Expected $expected, got $result: $pooler $directory" >&2
    exit 1
  fi
  if [ "$expected" = N/A ] && grep -q 'PostgreSQL started' "$log"; then
    echo 'Unsupported target started services before being filtered' >&2
    exit 1
  fi
  echo "$result $pooler $directory"
}

for pooler in pgbouncer odyssey pg_doorman; do
  expected=PASS
  [ "$pooler" != pg_doorman ] || expected=N/A
  check_case "$pooler" 030-test_no_user--test_no_user_password "$expected"
  check_case "$pooler" 031-test_no_user--test_no_user_password_forced_user "$expected"
done
# A supported control guards against accidentally filtering every Doorman test.
check_case pg_doorman 036-test_no_user--test_no_user_auth_user PASS
