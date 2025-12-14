# k8s-lab-gitops

Repositorio GitOps para el laboratorio de Kubernetes enterprise.

## Estructura

```
k8s-lab-gitops/
├── base/
│   ├── namespaces/          # Definición de namespaces
│   ├── common/              # Recursos compartidos entre aplicaciones
│   └── app-python-api-1/    # Base de python-api-1
│
└── overlays/
    ├── dev/                 # Configuración para desarrollo
    ├── staging/             # Configuración para staging
    └── prod/                # Configuración para producción
```

## Patrón de nombres de namespaces

`{app}-{entorno}`

Ejemplos:
- `python-api-1-dev`
- `python-api-1-staging`
- `python-api-1-prod`

## Comandos principales

### 1. Crear namespaces

```bash
kubectl apply -k base/namespaces/
```

### 2. Desplegar python-api-1 en dev

```bash
kubectl apply -k overlays/dev/python-api-1/
```

### 3. Desplegar python-api-1 en staging

```bash
kubectl apply -k overlays/staging/python-api-1/
```

### 4. Desplegar python-api-1 en prod

```bash
kubectl apply -k overlays/prod/python-api-1/
```

### 5. Ver YAML final generado sin aplicar

```bash
kubectl kustomize overlays/dev/python-api-1/
```

### 6. Ver diferencias antes de aplicar

```bash
kubectl diff -k overlays/prod/python-api-1/
```

### 7. Ver recursos desplegados

```bash
# Ver todo en un namespace
kubectl get all -n python-api-1-dev

# Ver pods específicos
kubectl get pods -n python-api-1-dev -l app=python-api-1

# Ver logs
kubectl logs -n python-api-1-dev -l app=python-api-1 -f
```

### 8. Eliminar deployment

```bash
kubectl delete -k overlays/dev/python-api-1/
```

## Configuración por entorno

### Dev
- **Réplicas**: 1
- **Recursos**: Sin límites definidos
- **Variables**: LOG_LEVEL=debug, ENVIRONMENT=development

### Staging
- **Réplicas**: 2
- **Recursos**: 256Mi RAM / 250m CPU (requests), 512Mi / 500m (limits)
- **Variables**: LOG_LEVEL=info, ENVIRONMENT=staging

### Prod
- **Réplicas**: 3
- **Recursos**: 512Mi RAM / 500m CPU (requests), 1Gi / 1000m (limits)
- **Variables**: LOG_LEVEL=warn, ENVIRONMENT=production

## Recursos creados

Cada deployment crea:
- 1 ConfigMap: `python-api-1-script` con el código Python
- 1 Deployment: `python-api-1-deploy` con los pods

## Añadir nueva aplicación

1. Crear base en `base/nueva-app/`
   - configmap.yaml
   - deployment.yaml
   - kustomization.yaml

2. Añadir namespaces en `base/namespaces/namespaces.yaml`

3. Crear overlays en `overlays/{env}/nueva-app/kustomization.yaml`

## Integración con ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: python-api-1-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/tu-usuario/k8s-lab-gitops
    targetRevision: main
    path: overlays/dev/python-api-1
  destination:
    server: https://kubernetes.default.svc
    namespace: python-api-1-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Troubleshooting

### Ver eventos de un namespace

```bash
kubectl get events -n python-api-1-dev --sort-by='.lastTimestamp'
```

### Verificar que Kustomize genera el YAML correctamente

```bash
kubectl kustomize overlays/dev/python-api-1/
```

### Ver configuración aplicada en un pod

```bash
kubectl describe pod -n python-api-1-dev -l app=python-api-1
```

## Archivos de referencia

- **COMMANDS.md**: Lista exhaustiva de comandos útiles
- **verify-structure.sh**: Script para verificar la estructura
