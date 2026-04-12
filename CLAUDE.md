# CLAUDE.md

## Project

z3rno-helm contains Helm charts for deploying Z3rno on Kubernetes. Currently a scaffold — no charts exist yet.

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
