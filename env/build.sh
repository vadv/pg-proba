#!/usr/bin/env bash
# Собирает docker-образ pg-proba-test-env из env/flake.nix.
# На хосте нужен ТОЛЬКО docker: nix живёт внутри контейнера.
# Кеш nix-store переживает сборки в persistent-контейнере pg-proba-nix-builder.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILDER="pg-proba-nix-builder"

nix_cmd() {
  docker exec -w /src "${BUILDER}" nix --extra-experimental-features "nix-command flakes" "$@"
}

# 1. Persistent nix-контейнер (store в его writable-слое)
if ! docker container inspect "${BUILDER}" >/dev/null 2>&1; then
  echo "[build] создаём nix-контейнер ${BUILDER}"
  docker run -d --privileged --name "${BUILDER}" -v "${ROOT}:/src" nixos/nix sleep infinity
fi
docker start "${BUILDER}" >/dev/null 2>&1 || true
# репо может принадлежать другому uid (CI-раннер) — libgit2 требует явного доверия
docker exec "${BUILDER}" git config --global --add safe.directory /src

# 2. flake.lock (первый раз)
if [ ! -f "${SCRIPT_DIR}/flake.lock" ]; then
  echo "[build] генерируем flake.lock"
  nix_cmd flake lock /src/env
fi

# 3. Сборка образа
echo "[build] nix build (первая сборка долгая: качает nixpkgs+инструменты)"
nix_cmd build /src/env#dockerImage --out-link /src/env/result

# 4. docker load
TAG="flake-$(cat "${SCRIPT_DIR}/flake.nix" "${SCRIPT_DIR}/flake.lock" | shasum -a 256 | cut -c1-16)"
echo "[build] docker load → pg-proba-test-env:${TAG}"
TARBALL="/src/env/result/image.tar.gz"
docker exec "${BUILDER}" test -f "${TARBALL}" || TARBALL="/src/env/result"
docker exec "${BUILDER}" cat "${TARBALL}" | docker load
docker tag "pg-proba-test-env:latest" "pg-proba-test-env:${TAG}"
echo "[build] готово: pg-proba-test-env:${TAG}"
