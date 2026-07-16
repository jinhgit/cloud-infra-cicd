#!/usr/bin/env bash
# Compose 기동 후 FE/BE curl 통합 테스트 (과금 없음)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE_UP=0
cleanup() {
  if [[ "$COMPOSE_UP" -eq 1 ]]; then
    docker compose down -v --remove-orphans >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "[integration] docker compose up -d --build"
docker compose up -d --build
COMPOSE_UP=1

echo "[integration] wait healthy..."
for i in $(seq 1 60); do
  if curl -sf http://127.0.0.1:8080/healthz >/dev/null \
    && curl -sf http://127.0.0.1:8080/health >/dev/null \
    && curl -sf http://127.0.0.1:3000/health >/dev/null; then
    break
  fi
  sleep 2
  if [[ $i -eq 60 ]]; then
    echo "timeout waiting for services"
    docker compose logs --tail=50
    exit 1
  fi
done

check() {
  local url="$1" expect="$2"
  body=$(curl -sf "$url")
  echo "$body" | grep -q "$expect" || {
    echo "FAIL $url expected /$expect/ got: $body"
    exit 1
  }
  echo "OK $url"
}

check http://127.0.0.1:8080/healthz "ok"
check http://127.0.0.1:8080/health '"status":"ok"'
check http://127.0.0.1:8080/api/hello "Hello from BE"
check http://127.0.0.1:3000/api/info "service"
check http://127.0.0.1:3000/api/info "gitSha"
check http://127.0.0.1:3000/api/info "version"

echo "[integration] ALL PASSED"
