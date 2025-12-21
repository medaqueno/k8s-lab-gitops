# Kubernetes Resource Naming Conventions

This document defines the naming conventions for all Kubernetes resources in the k8s-enterprise-lab project.

## General Principles

1. **Consistency**: All resources should follow the same naming pattern
2. **Readability**: Names should be descriptive and easy to understand
3. **Uniqueness**: Names should be unique within their scope
4. **Length**: Keep names concise (max 63 characters, DNS-1123 compliant)
5. **Environment**: Include environment in names when appropriate

## Resource Naming Patterns

### Namespaces

**Pattern**: `<environment>-<app-name>`

**Examples**:
- `dev-python-api-1`
- `prod-python-api-1`
- `staging-python-api-1`

### Deployments

**Pattern**: `<app-name>-deployment`

**Examples**:
- `python-api-1-deployment`
- `redis-cache-deployment`
- `postgres-db-deployment`

### Services

**Pattern**: `<app-name>-service`

**Examples**:
- `python-api-1-service`
- `redis-cache-service`
- `postgres-db-service`

### ConfigMaps

**Pattern**: `<app-name>-config`

**Examples**:
- `python-api-1-config`
- `redis-cache-config`
- `postgres-db-config`

### Secrets

**Pattern**: `<app-name>-secret`

**Examples**:
- `python-api-1-secret`
- `redis-cache-secret`
- `postgres-db-secret`

### Ingress/HTTPRoute

**Pattern**: `<app-name>-route`

**Examples**:
- `python-api-1-route`
- `redis-cache-route`
- `postgres-db-route`

### HorizontalPodAutoscaler

**Pattern**: `<app-name>-hpa`

**Examples**:
- `python-api-1-hpa`
- `redis-cache-hpa`
- `postgres-db-hpa`

### PodDisruptionBudget

**Pattern**: `<app-name>-pdb`

**Examples**:
- `python-api-1-pdb`
- `redis-cache-pdb`
- `postgres-db-pdb`

### NetworkPolicy

**Pattern**: `<app-name>-network-policy`

**Examples**:
- `python-api-1-network-policy`
- `redis-cache-network-policy`
- `postgres-db-network-policy`

## Label Naming Conventions

### Standard Labels

**Pattern**: Use standard Kubernetes label prefixes

**Examples**:
- `app.kubernetes.io/name`: `python-api-1`
- `app.kubernetes.io/instance`: `python-api-1`
- `app.kubernetes.io/version`: `1.0.0`
- `app.kubernetes.io/component`: `backend`
- `app.kubernetes.io/part-of`: `k8s-enterprise-lab`
- `app.kubernetes.io/managed-by`: `gitops`

### Environment Labels

**Pattern**: `environment: <environment-name>`

**Examples**:
- `environment: development`
- `environment: staging`
- `environment: production`

### Tier Labels

**Pattern**: `tier: <tier-name>`

**Examples**:
- `tier: frontend`
- `tier: backend`
- `tier: database`
- `tier: cache`
- `tier: messaging`

### Team Labels

**Pattern**: `team: <team-name>`

**Examples**:
- `team: platform-engineering`
- `team: backend-developers`
- `team: frontend-developers`

## Annotation Naming Conventions

### Description Annotations

**Pattern**: `description: "<resource-description>"`

**Examples**:
- `description: "Python API 1 backend application"`
- `description: "Redis cache for session storage"`

### GitOps Annotations

**Pattern**: `gitops.<key>: "<value>"`

**Examples**:
- `gitops.repo: "https://github.com/medaqueno/k8s-lab-gitops.git"`
- `gitops.path: "apps/python-api-1/base"`

### Monitoring Annotations

**Pattern**: `prometheus.io/<key>: "<value>"`

**Examples**:
- `prometheus.io/scrape: "true"`
- `prometheus.io/port: "8000"`
- `prometheus.io/path: "/metrics"`

## Environment-Specific Naming

### Development
- **Suffix**: `-dev`
- **Labels**: `environment: development`, `tier: development`
- **Annotations**: Include detailed descriptions and contact info

### Staging
- **Suffix**: `-staging` or `-stg`
- **Labels**: `environment: staging`, `tier: staging`
- **Annotations**: Include testing and validation info

### Production
- **Suffix**: `-prod`
- **Labels**: `environment: production`, `tier: production`
- **Annotations**: Include security and compliance info

## Resource Type Abbreviations

| Resource Type | Abbreviation |
|---------------|--------------|
| Deployment | deploy
| Service | svc
| ConfigMap | config
| Secret | secret
| Ingress | ingress
| HTTPRoute | route
| HorizontalPodAutoscaler | hpa
| PodDisruptionBudget | pdb
| NetworkPolicy | netpol
| PersistentVolumeClaim | pvc
| PersistentVolume | pv

## Best Practices

1. **Be Consistent**: Follow the same pattern across all resources
2. **Be Descriptive**: Use meaningful names that describe the resource
3. **Avoid Special Characters**: Use only lowercase alphanumeric characters and hyphens
4. **Keep It Short**: Maximum 63 characters (DNS-1123 compliant)
5. **Use Hyphens**: Separate words with hyphens, not underscores
6. **Include Environment**: When appropriate, include environment in the name
7. **Document**: Always document naming conventions and updates

## Examples

### Good Names
- `python-api-1-deployment`
- `redis-cache-service`
- `postgres-db-config`
- `frontend-app-route`
- `monitoring-prometheus-hpa`

### Bad Names
- `PythonAPI1Deployment` (mixed case)
- `python_api_1_deployment` (underscores)
- `papi1dep` (too short/abbreviated)
- `python-api-1-deployment-prod-us-east-1` (too long)
- `python.api.1.deployment` (dots not allowed)

## Implementation

All new resources should follow these naming conventions. Existing resources should be migrated to follow these conventions as part of regular maintenance cycles.

## Validation

Use tools like:
- `kubectl apply --dry-run=client` to validate names
- Kubernetes admission controllers
- CI/CD pipeline validation
- kubeval for YAML validation

## Future Enhancements

- Add automated naming validation in CI/CD
- Implement Kubernetes admission webhooks for naming validation
- Add tooling to generate resource names automatically