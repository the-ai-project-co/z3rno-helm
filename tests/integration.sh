#!/usr/bin/env bash
# integration.sh — Install Z3rno on a kind cluster and run smoke tests.
#
# Prerequisites:
#   - kind (https://kind.sigs.k8s.io/)
#   - helm 3.16+
#   - kubectl
#
# Usage:
#   ./tests/integration.sh
#
# This is a stub — full integration testing is deferred to a later phase.

set -euo pipefail

CLUSTER_NAME="${KIND_CLUSTER_NAME:-z3rno-test}"
NAMESPACE="${NAMESPACE:-z3rno-system}"
CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)/charts/z3rno"

echo "==> Creating kind cluster: ${CLUSTER_NAME}"
kind create cluster --name "${CLUSTER_NAME}" --wait 60s 2>/dev/null || true

echo "==> Creating namespace: ${NAMESPACE}"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing Z3rno chart"
helm install z3rno "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --wait \
  --timeout 120s

echo "==> Checking pod status"
kubectl get pods -n "${NAMESPACE}"

echo "==> Waiting for server to be ready"
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/component=server \
  -n "${NAMESPACE}" \
  --timeout=90s

echo "==> Running health check"
SERVER_POD=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/component=server -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "${NAMESPACE}" "${SERVER_POD}" -- curl -sf http://localhost:8000/v1/health || {
  echo "FAIL: Health check failed"
  exit 1
}

echo "==> Smoke tests passed"

echo "==> Cleaning up"
helm uninstall z3rno -n "${NAMESPACE}" || true
kind delete cluster --name "${CLUSTER_NAME}" || true

echo "==> Done"
