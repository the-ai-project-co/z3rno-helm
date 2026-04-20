# z3rno-helm

Helm charts for deploying Z3rno on Kubernetes. Includes the main `z3rno` chart with z3rno-server (FastAPI), Celery worker, and Valkey (Redis-compatible cache).

**License:** Apache 2.0
**Part of:** [Z3rno](https://github.com/the-ai-project-co) -- the database for AI agent memory

## Prerequisites

- Kubernetes 1.27+
- Helm 3.16+
- PostgreSQL 17 (managed externally via CloudNativePG, RDS, Cloud SQL, Neon, etc.)

## Quick Install

```bash
# Install with default values (requires DATABASE_URL)
helm install z3rno ./charts/z3rno -n z3rno-system --create-namespace \
  --set secrets.databaseUrl="postgresql://user:pass@postgres-host:5432/z3rno" \
  --set secrets.openaiApiKey="sk-..."
```

## Configuration

### Key Values

| Key | Default | Description |
|-----|---------|-------------|
| `server.image.repository` | `ghcr.io/the-ai-project-co/z3rno-server` | Server Docker image |
| `server.image.tag` | `latest` | Image tag |
| `server.replicas` | `2` | Number of server replicas |
| `server.port` | `8000` | Server port |
| `server.resources.requests.memory` | `256Mi` | Memory request |
| `server.resources.requests.cpu` | `250m` | CPU request |
| `server.resources.limits.memory` | `512Mi` | Memory limit |
| `server.resources.limits.cpu` | `500m` | CPU limit |
| `worker.enabled` | `true` | Enable Celery worker |
| `worker.replicas` | `1` | Number of worker replicas |
| `worker.command` | `celery -A z3rno_server.workers.celery_app worker --loglevel=info` | Worker command |
| `valkey.enabled` | `true` | Enable bundled Valkey |
| `valkey.image.tag` | `8` | Valkey image tag |
| `valkey.persistence.enabled` | `true` | Enable persistent volume for Valkey |
| `valkey.persistence.size` | `1Gi` | Valkey PVC size |
| `externalDatabase.enabled` | `false` | Use external PostgreSQL |
| `externalDatabase.host` | `""` | External DB hostname |
| `externalDatabase.port` | `5432` | External DB port |
| `externalDatabase.name` | `z3rno` | External DB name |
| `externalDatabase.user` | `z3rno` | External DB user |
| `externalDatabase.existingSecret` | `""` | Secret containing DB password |
| `externalDatabase.secretKey` | `password` | Key in the existing secret |
| `externalRedis.enabled` | `false` | Use external Redis instead of bundled Valkey |
| `externalRedis.host` | `""` | External Redis hostname |
| `externalRedis.port` | `6379` | External Redis port |
| `ingress.enabled` | `false` | Enable Ingress |
| `ingress.className` | `""` | Ingress class name |
| `ingress.annotations` | `{}` | Ingress annotations |
| `ingress.tls` | `[]` | TLS configuration |
| `secrets.databaseUrl` | `""` | PostgreSQL connection string |
| `secrets.redisUrl` | `""` | Redis/Valkey connection string (auto-generated if bundled) |
| `secrets.openaiApiKey` | `""` | OpenAI API key |
| `secrets.z3rnoApiKey` | `z3rno_sk_test_localdev` | Z3rno API key |
| `secrets.existingSecret` | `""` | Use an existing Kubernetes Secret |
| `env` | `{}` | Additional environment variables |
| `serviceAccount.create` | `true` | Create a ServiceAccount |
| `serviceAccount.name` | `""` | ServiceAccount name override |

### External Database Example

Connect to an existing PostgreSQL instance (RDS, Cloud SQL, CloudNativePG, etc.):

```bash
helm install z3rno ./charts/z3rno -n z3rno-system --create-namespace \
  --set secrets.databaseUrl="postgresql://z3rno:password@my-rds-instance.region.rds.amazonaws.com:5432/z3rno" \
  --set secrets.openaiApiKey="sk-..."
```

Or reference an existing Kubernetes Secret:

```bash
# Create the secret first
kubectl create secret generic z3rno-secrets -n z3rno-system \
  --from-literal=DATABASE_URL="postgresql://..." \
  --from-literal=REDIS_URL="redis://..." \
  --from-literal=OPENAI_API_KEY="sk-..." \
  --from-literal=Z3RNO_API_KEY="z3rno_sk_prod_..."

# Install referencing the existing secret
helm install z3rno ./charts/z3rno -n z3rno-system \
  --set secrets.existingSecret=z3rno-secrets
```

### External Redis Example

Use ElastiCache, Upstash, or another managed Redis instead of bundled Valkey:

```bash
helm install z3rno ./charts/z3rno -n z3rno-system --create-namespace \
  --set externalRedis.enabled=true \
  --set externalRedis.host="my-redis.cache.amazonaws.com" \
  --set secrets.databaseUrl="postgresql://..." \
  --set secrets.openaiApiKey="sk-..."
```

### Ingress with TLS Example

```yaml
# values-production.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.z3rno.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: z3rno-tls
      hosts:
        - api.z3rno.example.com
```

```bash
helm install z3rno ./charts/z3rno -n z3rno-system -f values-production.yaml \
  --set secrets.databaseUrl="postgresql://..." \
  --set secrets.openaiApiKey="sk-..."
```

## Verifying the Installation

```bash
# Check pod status
kubectl get pods -n z3rno-system -l app.kubernetes.io/instance=z3rno

# Port-forward to test locally
kubectl port-forward svc/z3rno-server 8000:8000 -n z3rno-system

# Health check
curl http://localhost:8000/v1/health
```

## Upgrading

```bash
helm upgrade z3rno ./charts/z3rno -n z3rno-system -f values-production.yaml
```

## Uninstalling

```bash
helm uninstall z3rno -n z3rno-system

# If you also want to remove the namespace
kubectl delete namespace z3rno-system
```

Note: Uninstalling the chart does **not** delete PersistentVolumeClaims created by the Valkey StatefulSet. To remove them:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=z3rno -n z3rno-system
```

## What This Is Not

- Not for local development. For `docker compose up`, see `docker-compose.dev.yml` in `z3rno-server/`.
- Not the full managed cloud IaC. Production cloud uses the private `z3rno-infra` Terraform repo, which references these charts.
