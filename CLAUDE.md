# CLAUDE.md

## Project

z3rno-helm contains Helm charts for deploying Z3rno on Kubernetes. Phase F slice 7 adds an optional region-aware deploy mode (off by default).

## Quick Reference

```bash
helm lint charts/z3rno/          # Lint chart (once created)
helm template z3rno charts/z3rno/ -f values-dev.yaml  # Render templates
helm install z3rno charts/z3rno/ -n z3rno-system      # Deploy
```

## Planned Architecture

- `charts/z3rno/` — Main chart: server Deployment, worker Deployment, Valkey, Ingress, HPA, ConfigMap, Secret
- `charts/z3rno-postgres/` — CloudNativePG Cluster resource with z3rno-postgres image
- `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml` — Environment configs

## Key Conventions

- Kubernetes 1.31+, Helm 3.16+
- CloudNativePG for PostgreSQL cluster management
- This repo is for Kubernetes deployment only (use docker-compose.dev.yml in z3rno-server for local dev)
- Currently empty scaffold — building the chart is a Phase 2 deliverable

## Phase F slice 7 — multi-region (opt-in)

When ``multiRegion.enabled=true`` in values.yaml:
- Every pod gets a ``z3rno.region`` label.
- Server / worker / beat deployments get a zonal ``topologySpreadConstraints`` (maxSkew=1, ScheduleAnyway).
- ``Z3RNO_REGION`` + optional ``Z3RNO_SECONDARY_REGIONS`` land in the configmap so logs/dashboards can scope by region.
- ``DATABASE_READ_URL`` lands in the secret (operator-prepared knob; engine read-router lands in v0.18).

Off by default — single-region deploys are byte-identical to v0.2.x. The chart now ships at ``0.3.0``.

Render test: ``bash tests/multi_region_render.sh``.
