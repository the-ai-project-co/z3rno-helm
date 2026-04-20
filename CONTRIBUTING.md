# Contributing to Z3rno Helm Chart

Thank you for your interest in contributing to the Z3rno Helm chart! This chart is how users deploy Z3rno on Kubernetes, so quality and reliability are critical.

## Getting started

### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) 3.16+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured for a cluster
- A local Kubernetes cluster for testing: [kind](https://kind.sigs.k8s.io/), [minikube](https://minikube.sigs.k8s.io/), or [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [helm-docs](https://github.com/norwoodj/helm-docs) (optional, for README generation)

### Repository structure

```
z3rno-helm/
  charts/
    z3rno/
      Chart.yaml           # Chart metadata
      values.yaml          # Default values
      templates/           # Kubernetes manifest templates
        _helpers.tpl        # Template helper functions
        deployment-server.yaml
        deployment-worker.yaml
        ...
```

## Development workflow

### 1. Make your changes

Edit templates in `charts/z3rno/templates/` or defaults in `charts/z3rno/values.yaml`.

### 2. Lint the chart

```bash
helm lint charts/z3rno/
```

Fix any warnings or errors before proceeding.

### 3. Render templates locally

Verify your templates render correctly with different value combinations:

```bash
# Default values
helm template z3rno charts/z3rno/

# With custom values
helm template z3rno charts/z3rno/ -f values-dev.yaml

# With specific overrides
helm template z3rno charts/z3rno/ --set server.replicas=3 --set ingress.enabled=true
```

### 4. Test on a local cluster

```bash
# Create a local cluster
kind create cluster --name z3rno-test

# Install the chart
helm install z3rno charts/z3rno/ -n z3rno-system --create-namespace

# Verify pods are running
kubectl get pods -n z3rno-system

# Check logs
kubectl logs -n z3rno-system -l app.kubernetes.io/component=server

# Clean up
helm uninstall z3rno -n z3rno-system
kind delete cluster --name z3rno-test
```

## Conventions

- **Template naming**: `deployment-<component>.yaml`, `service-<component>.yaml`
- **Helper functions**: Define in `_helpers.tpl`, prefix with `z3rno.`
- **Labels**: Use the standard Kubernetes labels (`app.kubernetes.io/name`, `app.kubernetes.io/component`, etc.)
- **Conditionals**: Gate optional resources with `.Values.<feature>.enabled`
- **Secrets**: Never hardcode secrets in templates. Use `existingSecret` pattern for production credentials.
- **Comments**: Add `# --` comments in `values.yaml` for helm-docs compatibility

## Pull request process

1. **Fork** the repository and create a branch from `main`.
2. **Make** your changes following the conventions above.
3. **Lint** with `helm lint charts/z3rno/`.
4. **Test** template rendering with `helm template`.
5. **Test** on a local kind or minikube cluster if your changes affect runtime behaviour.
6. **Bump** the chart version in `Chart.yaml` if your change affects the deployed chart.
7. **Submit** a pull request with a clear description.

### What makes a good PR

- One logical change per PR.
- Include the `helm template` output diff for non-trivial template changes.
- Document new values in `values.yaml` with comments.
- Update the README if you add new features or configuration options.

## Reporting issues

Found a bug or have a feature request? [Open an issue](https://github.com/the-ai-project-co/z3rno-helm/issues/new) with:

- Your Kubernetes version (`kubectl version`)
- Your Helm version (`helm version`)
- The values file you used (redact secrets)
- The error message or unexpected behaviour

## License

By contributing, you agree that your contributions will be licensed under the [Apache 2.0 License](LICENSE).
