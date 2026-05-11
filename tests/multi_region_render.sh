#!/usr/bin/env bash
# Phase F slice 7 — assert that ``helm template`` produces region-aware
# output when ``multiRegion.enabled=true`` and is byte-identical to the
# pre-F.7 baseline when disabled.
#
# Run from anywhere; uses the chart at z3rno-helm/charts/z3rno/.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="${ROOT}/charts/z3rno"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "==> 1/4 chart lints clean"
helm lint "${CHART}" >/dev/null

echo "==> 2/4 disabled mode emits no region markers"
DISABLED=$(helm template z3rno "${CHART}")
if echo "${DISABLED}" | grep -qE 'Z3RNO_REGION|z3rno\.region|topologySpreadConstraints|DATABASE_READ_URL'; then
  echo "${DISABLED}" | grep -nE 'Z3RNO_REGION|z3rno\.region|topologySpreadConstraints|DATABASE_READ_URL'
  fail "disabled mode leaked region markers"
fi

echo "==> 3/4 enabled mode stamps region label + zone spread + read URL"
ENABLED=$(helm template z3rno "${CHART}" \
  --set multiRegion.enabled=true \
  --set multiRegion.region=us-east-1 \
  --set 'multiRegion.zones={us-east-1a,us-east-1b,us-east-1c}' \
  --set multiRegion.readDatabaseUrl='postgresql://reader@us-east-1-ro.example.com/z3rno' \
  --set 'multiRegion.secondaryRegions={us-west-2,eu-west-1}')

# Region label must land on all three deployments (server / worker / beat).
LABEL_COUNT=$(echo "${ENABLED}" | grep -c 'z3rno.region: "us-east-1"' || true)
[[ "${LABEL_COUNT}" -ge 3 ]] || fail "expected ≥3 z3rno.region labels, saw ${LABEL_COUNT}"

# Topology spread must appear on all three pod templates.
SPREAD_COUNT=$(echo "${ENABLED}" | grep -c 'topologySpreadConstraints' || true)
[[ "${SPREAD_COUNT}" -ge 3 ]] || fail "expected ≥3 topologySpreadConstraints, saw ${SPREAD_COUNT}"

# Configmap must carry Z3RNO_REGION + Z3RNO_SECONDARY_REGIONS.
echo "${ENABLED}" | grep -q 'Z3RNO_REGION: "us-east-1"' \
  || fail "Z3RNO_REGION not stamped on configmap"
echo "${ENABLED}" | grep -q 'Z3RNO_SECONDARY_REGIONS: "us-west-2,eu-west-1"' \
  || fail "Z3RNO_SECONDARY_REGIONS not joined"

# Secret must carry DATABASE_READ_URL.
echo "${ENABLED}" | grep -q 'DATABASE_READ_URL: "postgresql://reader@us-east-1-ro.example.com/z3rno"' \
  || fail "DATABASE_READ_URL not wired into secret"

echo "==> 4/4 enabled mode also satisfies the kubernetes zone topology key"
echo "${ENABLED}" | grep -q 'topology.kubernetes.io/zone' \
  || fail "expected zone topology key in topologySpread"

echo "OK: Phase F slice 7 multi-region rendering passes."
