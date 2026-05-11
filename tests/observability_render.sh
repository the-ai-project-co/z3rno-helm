#!/usr/bin/env bash
# Phase G slice 7 — assert observability artifacts render when enabled
# and are absent when disabled.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="${ROOT}/charts/z3rno"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "==> 1/3 chart lints clean"
helm lint "${CHART}" >/dev/null

echo "==> 2/3 disabled mode emits no Prometheus / Grafana artifacts"
DISABLED=$(helm template z3rno "${CHART}")
if echo "${DISABLED}" | grep -qE 'PrometheusRule|grafana_dashboard'; then
  fail "disabled mode leaked observability artifacts"
fi

echo "==> 3/3 enabled mode renders rules + dashboard + 4 SLO recordings"
ENABLED=$(helm template z3rno "${CHART}" \
  --set observability.prometheusRules.enabled=true \
  --set observability.grafanaDashboard.enabled=true)

echo "${ENABLED}" | grep -q "kind: PrometheusRule" \
  || fail "PrometheusRule resource missing"
echo "${ENABLED}" | grep -q 'grafana_dashboard: "1"' \
  || fail "Grafana sidecar label missing"
for record in \
  z3rno:slo:recall_p95_seconds \
  z3rno:slo:ingest_success_rate \
  z3rno:slo:distill_error_rate \
  z3rno:slo:audit_chain_freshness_seconds
do
  echo "${ENABLED}" | grep -q "${record}" \
    || fail "recording rule ${record} missing"
done

# Four alert rules — one per SLO.
ALERT_COUNT=$(echo "${ENABLED}" | grep -c "^        - alert:" || true)
[[ "${ALERT_COUNT}" -ge 4 ]] \
  || fail "expected ≥4 alert rules, saw ${ALERT_COUNT}"

echo "OK: Phase G slice 7 observability rendering passes."
