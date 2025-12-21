# Namespaces Configuration

This directory contains the namespace definitions and configurations for the Kubernetes cluster.

## Structure

```
namespaces/
├── base/                  # Base namespace configurations
│   ├── python-api-1-namespace.yaml  # Base namespace definition
│   ├── resource-quota.yaml         # Base resource quota
│   ├── kustomization.yaml         # Kustomize configuration
│   └── kustomizeconfig.yaml       # Kustomize configuration
└── overlays/               # Environment-specific overlays
    ├── dev/                # Development environment
    │   └── kustomization.yaml
    └── prod/               # Production environment
        └── kustomization.yaml
```

## Features

### Standardized Labels
- `kubernetes.io/metadata.name`: Standard Kubernetes label
- `environment`: Environment (development/production)
- `app.kubernetes.io/*`: Application metadata
- `team`: Owning team
- `owner`: Owner information
- `cost-center`: Cost tracking
- `monitoring`: Monitoring status
- `logging`: Logging status
- `security-level`: Security classification
- `compliance-tier`: Compliance classification

### Standardized Annotations
- `description`: Namespace description
- `contact`: Contact information
- `change-management`: Change management process
- `cost-center-code`: Cost center code
- `prometheus.io/scrape`: Prometheus scraping
- `security-contact`: Security contact
- `compliance-owner`: Compliance owner
- `gitops.*`: GitOps metadata

### Resource Quotas
- **Development**: More relaxed quotas for development flexibility
- **Production**: Stricter quotas for production stability
- Compute resources (CPU, memory)
- Storage resources
- Object counts (pods, services, etc.)

## Usage

### Apply Development Namespace

```bash
kubectl apply -k namespaces/overlays/dev/
```

### Apply Production Namespace

```bash
kubectl apply -k namespaces/overlays/prod/
```

### View Generated Configuration

```bash
kustomize build namespaces/overlays/dev/
kustomize build namespaces/overlays/prod/
```

## Best Practices

1. **Namespace Naming**: Use `<environment>-<app-name>` pattern
2. **Labeling**: Always include standard labels for observability
3. **Resource Quotas**: Set appropriate quotas for each environment
4. **Documentation**: Include descriptive annotations
5. **Security**: Classify namespaces by security level

## Environment Differences

| Aspect | Development | Production |
|--------|-------------|------------|
| Resource Quotas | Relaxed | Strict |
| Security Level | Standard | High |
| Compliance Tier | Medium | High |
| Monitoring | Enabled | Enabled |
| Cost Tracking | Detailed | Detailed |

## Integration with ArgoCD

The namespaces are designed to work with ArgoCD's `CreateNamespace=true` feature. The ArgoCD applications will automatically create these namespaces when deploying applications.

## Future Enhancements

- Add network policies per namespace
- Implement pod security standards
- Add limit ranges
- Implement namespace lifecycle management