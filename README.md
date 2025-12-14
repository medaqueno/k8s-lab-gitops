# k8s-lab-gitops

Guía directa para desplegar aplicaciones en Kubernetes usando GitOps con Kustomize.

## 📁 Estructura del Proyecto

```
k8s-lab-gitops/
├── base/                          # Recursos base (comunes a todos los entornos)
│   ├── namespaces/                  # Definición de namespaces
│   │   ├── namespaces.yaml            # Define 3 namespaces (dev/staging/prod)
│   │   └── kustomization.yaml         # Configuración kustomize
│   ├── common/                      # Recursos compartidos
│   │   └── kustomization.yaml         # Base para recursos compartidos
│   └── app-python-api-1/            # Aplicación Python
│       ├── configmap.yaml             # Script Python como ConfigMap
│       ├── deployment.yaml            # Deployment base
│       └── kustomization.yaml         # Configuración kustomize
└── overlays/                        # Configuración por entorno
    ├── dev/                           # Desarrollo
    │   └── python-api-1/                 # Overlay para dev
    │       └── kustomization.yaml           # Configuración específica
    ├── staging/                       # Staging
    │   └── python-api-1/                 # Overlay para staging
    │       └── kustomization.yaml           # Configuración específica
    └── prod/                          # Producción
        └── python-api-1/                 # Overlay para prod
            └── kustomization.yaml           # Configuración específica
```

## 🚀 Despliegue Rápido

### 1. Crear Namespaces

```bash
kubectl apply -k base/namespaces/
```

### 2. Desplegar en Desarrollo

```bash
kubectl apply -k overlays/dev/python-api-1/
```

### 3. Desplegar en Staging

```bash
kubectl apply -k overlays/staging/python-api-1/
```

### 4. Desplegar en Producción

```bash
kubectl apply -k overlays/prod/python-api-1/
```

## 🔄 Gestión de Despliegues

### Reiniciar Pods (Método Recomendado)

Usa `kubectl rollout restart` para forzar la recreación de pods cuando necesites aplicar cambios en ConfigMaps o Secrets:

```bash
# Reiniciar deployment
kubectl rollout restart deployment/python-api-1-deploy -n python-api-1-dev

# Verificar estado del rollout
kubectl rollout status deployment/python-api-1-deploy -n python-api-1-dev

# Ver historial de rollouts
kubectl rollout history deployment/python-api-1-deploy -n python-api-1-dev
```

**Ventajas**:
- ✅ Más limpio que eliminar pods directamente
- ✅ Preserva el historial de despliegues
- ✅ Añade anotación automática `kubectl.kubernetes.io/restartedAt`
- ✅ Permite monitorear el progreso

### Actualizar ConfigMaps

Los cambios en ConfigMaps no se aplican automáticamente a los pods existentes:

```bash
# 1. Aplicar el ConfigMap actualizado
kubectl apply -f base/app-python-api-1/configmap.yaml

# 2. Reiniciar pods para que recojan los cambios
kubectl rollout restart deployment/python-api-1-deploy -n python-api-1-dev

# 3. Verificar que los nuevos pods tienen los cambios
kubectl logs -n python-api-1-dev -l app=python-api-1 --tail=20
```

### Rollback

```bash
# Ver historial de revisiones
kubectl rollout history deployment/python-api-1-deploy -n python-api-1-dev

# Volver a una revisión anterior
kubectl rollout undo deployment/python-api-1-deploy -n python-api-1-dev --to-revision=2
```

## 📊 Verificación

### Ver Recursos

```bash
# Ver todos los recursos en un namespace
kubectl get all -n python-api-1-dev

# Ver pods con detalles
kubectl get pods -n python-api-1-dev -o wide

# Ver logs
kubectl logs -n python-api-1-dev -l app=python-api-1 --follow
```

### Ver YAML Generado

```bash
# Ver la configuración final que se aplicará
kustomize build overlays/dev/python-api-1/
```

## 🎯 Buenas Prácticas

### Configuración Recomendada para Deployments

```yaml
spec:
  revisionHistoryLimit: 3  # Conservar solo las últimas 3 revisiones
  progressDeadlineSeconds: 600  # Tiempo máximo para completar el rollout
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1  # Máximo de pods adicionales durante el update
      maxUnavailable: 0  # Máximo de pods no disponibles
```

### Seguridad

Para corregir advertencias de PodSecurity:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: python-api-1
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

### Actualización de Kustomize

Si ves advertencias sobre `commonLabels` deprecated:

```bash
cd base/app-python-api-1
kustomize edit fix
```

## 🔗 Flujo de Trabajo Recomendado

```bash
# 1. Hacer cambios en los archivos base
git pull origin main
# Editar archivos en base/app-python-api-1/

# 2. Probar en desarrollo
kubectl apply -k overlays/dev/python-api-1/
kubectl get pods -n python-api-1-dev -w

# 3. Validar en staging
kubectl apply -k overlays/staging/python-api-1/
kubectl get pods -n python-api-1-staging

# 4. Desplegar en producción
kubectl apply -k overlays/prod/python-api-1/
kubectl get pods -n python-api-1-prod

# 5. Si necesitas reiniciar pods (ej: después de actualizar ConfigMap)
kubectl rollout restart deployment/python-api-1-deploy -n python-api-1-prod
```

## 📝 Notas

- **Namespaces**: Cada entorno tiene su propio namespace (`python-api-1-dev`, `python-api-1-staging`, `python-api-1-prod`)
- **Réplicas**: 1 en dev, 2 en staging, 3 en producción
- **Recursos**: Sin límites en dev, con límites en staging/prod
- **Variables de entorno**: Diferentes niveles de logging por entorno (debug/info/warn)

## 🔧 Comandos Útiles

```bash
# Ver eventos
kubectl get events -n python-api-1-dev --sort-by='.lastTimestamp'

# Escalar aplicación
kubectl scale deployment -n python-api-1-dev python-api-1-deploy --replicas=3

# Eliminar recursos
kubectl delete -k overlays/dev/python-api-1/

# Ver detalles de un pod
kubectl describe pod -n python-api-1-dev <nombre-del-pod>

# Ver detalles de un deployment
kubectl describe deployment -n python-api-1-dev python-api-1-deploy
```
