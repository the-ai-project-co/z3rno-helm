# z3rno-helm

> Helm charts for deploying Z3rno on Kubernetes. Includes the main `z3rno` chart (z3rno-server + Celery worker + Valkey) and a CloudNativePG cluster definition for PostgreSQL 17 with pgvector, pgvectorscale, Apache AGE, and pg_cron pre-installed.

**License:** Apache 2.0
**Status:** Early development
**Part of:** [Z3rno](https://github.com/the-ai-project-co) — the database for AI agent memory

## Charts

- `charts/z3rno/` — Main chart: `z3rno-server` Deployment, HPA, Ingress, ConfigMap, Secret, Celery worker Deployment, Valkey StatefulSet
- `charts/z3rno-postgres/` — CloudNativePG `Cluster` resource using the pre-built `ghcr.io/the-ai-project-co/z3rno-postgres:17` image with all required extensions

## Quickstart

```bash
# Install CloudNativePG operator (one-time, cluster-wide)
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.25/releases/cnpg-1.25.0.yaml

# Install Z3rno postgres cluster
helm install z3rno-postgres ./charts/z3rno-postgres -n z3rno-system --create-namespace

# Install Z3rno server + worker + valkey
helm install z3rno ./charts/z3rno -n z3rno-system \
  -f charts/z3rno/values-dev.yaml
```

## Prerequisites

- Kubernetes 1.31+
- Helm 3.16+
- CloudNativePG operator (for PostgreSQL cluster management)
- cert-manager (for automatic TLS via Let's Encrypt / ACM)

## What this is not

- Not for local development. For `docker compose up`, see the `docker-compose.dev.yml` in `z3rno-server/`.
- Not the full managed cloud IaC. Production cloud uses the private `z3rno-infra` Terraform repo, which references these charts.
