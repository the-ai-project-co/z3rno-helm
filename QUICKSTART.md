# Quickstart: z3rno-helm

A detailed getting-started guide for deploying Z3rno on Kubernetes with Helm.

## Prerequisites

- Kubernetes 1.27+ cluster (minikube, kind, EKS, GKE, AKS, etc.)
- Helm 3.16+
- kubectl configured to access your cluster
- An externally managed PostgreSQL 17 instance with pgvector and Apache AGE
- An OpenAI API key (for embeddings)

## Step-by-step Installation

### 1. Clone the repository

```bash
git clone https://github.com/the-ai-project-co/z3rno-helm.git
cd z3rno-helm
```

### 2. Create a namespace

```bash
kubectl create namespace z3rno-system
```

### 3. Install the chart

```bash
helm install z3rno ./charts/z3rno -n z3rno-system \
  --set secrets.databaseUrl="postgresql://z3rno:password@your-postgres-host:5432/z3rno" \
  --set secrets.openaiApiKey="sk-..."
```

### 4. Verify the deployment

```bash
kubectl get pods -n z3rno-system -l app.kubernetes.io/instance=z3rno
```

Wait until all pods show `Running` status.

## Running Locally (with minikube or kind)

### Using kind

```bash
# Create a local cluster
kind create cluster --name z3rno

# Install (you still need an external Postgres)
helm install z3rno ./charts/z3rno -n z3rno-system --create-namespace \
  --set secrets.databaseUrl="postgresql://z3rno:password@host.docker.internal:5432/z3rno" \
  --set secrets.openaiApiKey="sk-..."

# Port-forward to access the API
kubectl port-forward svc/z3rno-server 8000:8000 -n z3rno-system
```

### Test it

```bash
curl http://localhost:8000/v1/health
# {"status": "ok"}

curl -X POST http://localhost:8000/v1/memories \
  -H "Authorization: Bearer z3rno_sk_test_localdev" \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "agent-1", "content": "Hello from Kubernetes", "memory_type": "semantic"}'
```

## First Working Example

A minimal `values.yaml` for local testing:

```yaml
server:
  replicas: 1
  resources:
    requests:
      memory: 128Mi
      cpu: 100m

worker:
  enabled: true
  replicas: 1

valkey:
  enabled: true

secrets:
  databaseUrl: "postgresql://z3rno:password@host.docker.internal:5432/z3rno"
  openaiApiKey: "sk-..."
  z3rnoApiKey: "z3rno_sk_test_localdev"
```

Install with:

```bash
helm install z3rno ./charts/z3rno -n z3rno-system --create-namespace -f values.yaml
```

## Upgrading

```bash
helm upgrade z3rno ./charts/z3rno -n z3rno-system -f values.yaml
```

## Uninstalling

```bash
helm uninstall z3rno -n z3rno-system
kubectl delete pvc -l app.kubernetes.io/instance=z3rno -n z3rno-system  # remove Valkey PVCs
```

## Common Issues / Troubleshooting

### 1. Pods stuck in CrashLoopBackOff

Check logs:

```bash
kubectl logs -n z3rno-system deploy/z3rno-server --tail=50
```

Most common cause: invalid `DATABASE_URL` or the database is unreachable from inside the cluster.

### 2. "Host not found" for database URL

If PostgreSQL runs outside the cluster, ensure the hostname is resolvable from within Kubernetes. Use the full DNS name or IP. For local development with kind/minikube, use `host.docker.internal` (kind) or the host IP.

### 3. Valkey pod pending (no storage class)

If your cluster does not have a default StorageClass, disable Valkey persistence:

```bash
--set valkey.persistence.enabled=false
```

### 4. Ingress not working

Ensure you have an Ingress controller installed (nginx-ingress, Traefik, etc.) and that `ingress.className` matches your controller's class.

### 5. Image pull errors

The server image is at `ghcr.io/the-ai-project-co/z3rno-server`. If your cluster requires authentication to pull from GHCR, configure an `imagePullSecret`.
