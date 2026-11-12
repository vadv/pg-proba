#!/usr/bin/env bash
# Прогон тестов pg-proba в Linux-окружении. На хосте нужен ТОЛЬКО docker.
#
#   env/run.sh shell                  — bash внутри образа
#   env/run.sh test <pooler> <feat>   — один тест: env/run.sh test odyssey features/protocol/0001-*/steps.feature
#   env/run.sh matrix                 — вся матрица: каждый features/*/*/steps.feature × odyssey/pgbouncer/pg_doorman
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE="pg-proba-test-env:flake-$(cat "${SCRIPT_DIR}/flake.nix" "${SCRIPT_DIR}/flake.lock" | shasum -a 256 | cut -c1-16)"

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "[run] образ ${IMAGE} не найден — сначала env/build.sh" >&2
  exit 1
fi

run_in_container() {
  local cmd="$1"
  local interactive="${2:-false}"
  local args=(
    --rm --init
    -v "${ROOT}:/workspace"
    -w /workspace
    --tmpfs /tmp:exec,mode=1777
    -v pg_proba_cargo_registry:/root/.cargo/registry
    -v pg_proba_cargo_git:/root/.cargo/git
    -v pg_proba_gomod:/root/go/pkg/mod
    -v pg_proba_nuget:/root/.nuget/packages
    -v pg_proba_m2:/root/.m2/repository
    -v pg_proba_npm:/root/.npm-global
  )
  [ -t 1 ] && args+=(-t)
  [ "$interactive" = "true" ] && args+=(-i -t)
  docker run "${args[@]}" "${IMAGE}" bash -c "${cmd}"
}

case "${1:-matrix}" in
  shell)
    docker run --rm -init -i -t \
      -v "${ROOT}:/workspace" -w /workspace \
      --tmpfs /tmp:exec,mode=1777 \
      -v pg_proba_cargo_registry:/root/.cargo/registry \
      -v pg_proba_cargo_git:/root/.cargo/git \
      -v pg_proba_gomod:/root/go/pkg/mod \
      -v pg_proba_nuget:/root/.nuget/packages \
      -v pg_proba_m2:/root/.m2/repository \
      -v pg_proba_npm:/root/.npm-global \
      "${IMAGE}" bash
    ;;
  test)
    pooler="${2:?pooler: odyssey|pgbouncer|pg_doorman}"
    features="${3:?путь до .feature}"
    run_in_container "POOLER=${pooler} FEATURES=${features} cargo test --test bdd"
    ;;
  matrix)
    echo "pooler      test                                            результат"
    for f in "${ROOT}"/features/*/*/steps.feature; do
      rel="${f#"${ROOT}"/}"
      for p in odyssey pgbouncer pg_doorman; do
        if res=$(run_in_container "POOLER=${p} FEATURES=${rel} cargo test --test bdd" 2>&1); then
          status="PASS"
        else
          status="FAIL"
        fi
        summary=$(echo "$res" | grep -E "scenario \(" | tail -1)
        printf '%-11s %-47s %s %s\n' "$p" "$rel" "$status" "${summary:+($summary)}"
      done
    done
    ;;
  *)
    echo "использование: $0 shell | test <pooler> <feature> | matrix" >&2
    exit 1
    ;;
esac
