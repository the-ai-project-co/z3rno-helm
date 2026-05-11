#!/usr/bin/env bash
# v0.19.7 — assert the z3rno-postgres subchart renders a CNPG Cluster
# CR when enabled and stays absent when disabled.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="${ROOT}/charts/z3rno"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "==> 1/4 chart lints clean"
helm dependency update "${CHART}" >/dev/null
helm lint "${CHART}" >/dev/null

echo "==> 2/4 disabled mode emits no Cluster CR"
DISABLED=$(helm template z3rno "${CHART}")
if echo "${DISABLED}" | grep -q "kind: Cluster"; then
  fail "disabled mode rendered a Cluster CR"
fi

echo "==> 3/4 enabled mode renders the Cluster"
ENABLED=$(helm template z3rno "${CHART}" --set z3rno-postgres.enabled=true)
echo "${ENABLED}" | grep -q "kind: Cluster" \
  || fail "Cluster resource missing"
echo "${ENABLED}" | grep -q 'imageName: "ghcr.io/the-ai-project-co/z3rno-postgres:17"' \
  || fail "z3rno-postgres image not pinned"
echo "${ENABLED}" | grep -q "instances: 3" \
  || fail "expected default 3 instances (1 primary + 2 replicas)"

echo "==> 4/4 enabled mode CREATEs all 5 extensions"
for ext in vector age pg_cron pgaudit pgcrypto; do
  echo "${ENABLED}" | grep -q "CREATE EXTENSION IF NOT EXISTS ${ext}" \
    || fail "extension ${ext} missing from postInitSQL"
done

echo "OK: v0.19.7 z3rno-postgres subchart rendering passes."
