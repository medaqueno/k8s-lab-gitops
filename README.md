# k8s-lab-gitops

Guía directa para desplegar aplicaciones en Kubernetes usando GitOps.

## 📁 Estructura Actual y Propósito de Archivos

```
k8s-lab-gitops/
├── base/                          # Recursos base (comunes a todos los entornos)
│   ├── namespaces/                  # Definición de namespaces para todos los entornos
│   │   ├── namespaces.yaml            # Define los 3 namespaces con sus labels
│   │   └── kustomization.yaml         # Configuración kustomize para namespaces
│   ├── common/                      # Recursos compartidos entre aplicaciones
│   │   └── kustomization.yaml         # Base para recursos compartidos
│   └── app-python-api-1/            # Configuración base de la aplicación Python
│       ├── configmap.yaml             # ConfigMap con el script Python (client.py)
│       ├── deployment.yaml            # Deployment base (sin configuración de entorno)
│       └── kustomization.yaml         # Configuración kustomize base
└── overlays/                        # Configuración específica por entorno
    ├── dev/                           # Configuración para desarrollo
    │   └── python-api-1/                 # Overlay que sobrescribe configuración base
    │       └── kustomization.yaml           # Define namespace, labels y patches para dev
    ├── staging/                       # Configuración para staging
    │   └── python-api-1/                 # Overlay que sobrescribe configuración base
    │       └── kustomization.yaml           # Define namespace, labels y patches para staging
    └── prod/                          # Configuración para producción
        └── python-api-1/                 # Overlay que sobrescribe configuración base
            └── kustomization.yaml           # Define namespace, labels y patches para prod
```

### Detalle de Archivos y Su Propósito

#### `base/namespaces/namespaces.yaml`

**Propósito**: Define los 3 namespaces con sus etiquetas correspondientes.
**Contenido**:

- `python-api-1-dev`: Namespace para desarrollo
- `python-api-1-staging`: Namespace para staging
- `python-api-1-prod`: Namespace para producción
  **Etiquetas**: `app`, `environment`, `lab-group`, `managed-by`

#### `base/namespaces/kustomization.yaml`

**Propósito**: Configuración kustomize para generar los namespaces.
**Contenido**:

- `resources`: Lista de archivos YAML a procesar
- `commonLabels`: Etiquetas comunes a todos los namespaces

#### `base/app-python-api-1/configmap.yaml`

**Propósito**: Define un ConfigMap con el script Python que se ejecutará.
**Contenido**:

- `client.py`: Script Python que hace requests HTTP a `echo-server-svc`
- El script se monta en `/app/client.py` en el contenedor

#### `base/app-python-api-1/deployment.yaml`

**Propósito**: Define el deployment base de la aplicación.
**Contenido**:

- `metadata.name`: `python-api-1-deploy`
- `replicas`: 1 (se sobrescribe en overlays)
- `containers`: Configuración del contenedor Python
- `volumeMounts`: Monta el ConfigMap en `/app`
- `env.SERVICE_URL`: Variable de entorno para el servicio destino

#### `base/app-python-api-1/kustomization.yaml`

**Propósito**: Configuración kustomize base para la aplicación.
**Contenido**:

- `resources`: Archivos base (configmap.yaml, deployment.yaml)
- `commonLabels`: Etiquetas comunes (`app`, `managed-by`)
- `commonAnnotations`: Anotaciones comunes

#### `overlays/dev/python-api-1/kustomization.yaml`

**Propósito**: Sobrescribe la configuración base para desarrollo.
**Contenido**:

- `resources`: Referencia a la configuración base
- `namespace`: `python-api-1-dev`
- `commonLabels`: Añade `environment: dev`
- `patchesStrategicMerge`: Sobrescribe replicas y variables de entorno

#### `overlays/staging/python-api-1/kustomization.yaml`

**Propósito**: Sobrescribe la configuración base para staging.
**Contenido**:

- `resources`: Referencia a la configuración base
- `namespace`: `python-api-1-staging`
- `commonLabels`: Añade `environment: staging`
- `replicas`: 2 réplicas
- `patches`: Define recursos y variables de entorno para staging

#### `overlays/prod/python-api-1/kustomization.yaml`

**Propósito**: Sobrescribe la configuración base para producción.
**Contenido**:

- `resources`: Referencia a la configuración base
- `namespace`: `python-api-1-prod`
- `commonLabels`: Añade `environment: prod`
- `replicas`: 3 réplicas
- `patches`: Define recursos y variables de entorno para producción

### Jerarquía de Sobrescritura

```
BASE (base/app-python-api-1/)
   ↓ Sobrescritura por entorno
DEV (overlays/dev/python-api-1/)
   ↓ Promoción
STAGING (overlays/staging/python-api-1/)
   ↓ Promoción
PROD (overlays/prod/python-api-1/)
```

**Qué se sobrescribe en cada overlay:**

1. `namespace`: Define el namespace específico
2. `commonLabels.environment`: Añade la etiqueta de entorno
3. `replicas`: Número de réplicas (1/2/3)
4. `resources`: Límites de CPU/Memoria (solo staging/prod)
5. `env`: Variables de entorno específicas (LOG_LEVEL, ENVIRONMENT)

## Despliegue Paso a Paso

### 1. Crear Namespaces

```bash
kubectl apply -k base/namespaces/
```

Verificar:

```bash
kubectl get namespaces -l lab-group=k8s-lab
```

### 2. Desplegar en Desarrollo

```bash
cd overlays/dev/python-api-1
kustomize build . | kubectl apply -f -
```

Verificar:

```bash
kubectl get all -n python-api-1-dev
kubectl logs -n python-api-1-dev -l app=python-api-1
```

### 3. Desplegar en Staging

```bash
cd overlays/staging/python-api-1
kustomize build . | kubectl apply -f -
```

Verificar:

```bash
kubectl get all -n python-api-1-staging
```

### 4. Desplegar en Producción

```bash
cd overlays/prod/python-api-1
kustomize build . | kubectl apply -f -
```

Verificar:

```bash
kubectl get all -n python-api-1-prod
```

## Redespliegue

### Actualizar Aplicación

1. Modificar archivos en `base/app-python-api-1/`
2. Verificar YAML generado:
   ```bash
   kustomize build overlays/dev/python-api-1/
   ```
3. Aplicar cambios en desarrollo:
   ```bash
   kustomize build overlays/dev/python-api-1/ | kubectl apply -f -
   ```
4. Promover a staging y producción cuando esté listo

### Forzar Redespliegue (Método Recomendado)

**Mejor Práctica**: Usar `kubectl rollout restart` (disponible desde Kubernetes v1.15+)

```bash
# Reiniciar deployment para forzar recreación de pods
kubectl rollout restart deployment/python-api-1-deploy -n python-api-1-dev
```

**Ventajas**:
- Más limpio que eliminar/volver a crear
- Preserva el historial de despliegues
- Añade anotación automática `kubectl.kubernetes.io/restartedAt`
- Permite monitorear el progreso del rollout

### Métodos Alternativos

```bash
# Opción 1: Eliminar pod directamente (rápido pero menos controlado)
kubectl delete pod -n python-api-1-dev -l app=python-api-1

# Opción 2: Usar kubectl scale (más controlado)
kubectl scale deployment -n python-api-1-dev python-api-1-deploy --replicas=0
kubectl scale deployment -n python-api-1-dev python-api-1-deploy --replicas=1

# Opción 3: Usar annotate para forzar redeploy (manual)
kubectl annotate deployment -n python-api-1-dev python-api-1-deploy \
  kubectl.kubernetes.io/restartedAt=$(date +%Y-%m-%dT%H:%M:%S%z) --overwrite
```

## Monitoreo de Rollout

### Verificar Estado del Rollout

```bash
# Ver estado del rollout
kubectl rollout status deployment/python-api-1-deploy -n python-api-1-dev

# Ver historial de rollouts
kubectl rollout history deployment/python-api-1-deploy -n python-api-1-dev

# Ver detalles de una revisión específica
kubectl rollout history deployment/python-api-1-deploy -n python-api-1-dev --revision=1
```

### Verificar Pods Reiniciados

```bash
# Ver pods antes y después del restart
kubectl get pods -n python-api-1-dev --show-labels

# Verificar que los nuevos pods están corriendo
kubectl get pods -n python-api-1-dev -w

# Ver detalles del nuevo pod
kubectl describe pod -n python-api-1-dev <nombre-del-nuevo-pod>
```

### Verificar Anotaciones de Restart

```bash
# Ver anotaciones del deployment
kubectl get deployment -n python-api-1-dev python-api-1-deploy -o jsonpath='{.metadata.annotations}'

# Filtrar solo la anotación de restart
kubectl get deployment -n python-api-1-dev python-api-1-deploy -o jsonpath='{.metadata.annotations.kubectl\.kubernetes\.io/restartedAt}'
```

## Configuración por Entorno

### Desarrollo

- **Namespace**: `python-api-1-dev`
- **Réplicas**: 1
- **Recursos**: Sin límites
- **Variables**: `LOG_LEVEL=debug`, `ENVIRONMENT=development`

### Actualización de ConfigMaps

**Importante**: Los cambios en ConfigMaps NO se aplican automáticamente a los pods existentes. Cuando actualices el script Python en el ConfigMap, necesitarás reiniciar los pods para que recojan los cambios:

```bash
# Aplicar el ConfigMap actualizado
kubectl apply -f base/app-python-api-1/configmap.yaml

# Reiniciar el deployment para que los pods recojan los cambios
# Método recomendado (Kubernetes v1.15+):
kubectl rollout restart deployment/python-api-1-deploy -n python-api-1-dev
```

**Alternativas**:

```bash
# Opción 1: Eliminar pod directamente (rápido pero menos controlado)
kubectl delete pod -n python-api-1-dev -l app=python-api-1

# Opción 2: Usar kubectl scale (más controlado)
kubectl scale deployment -n python-api-1-dev python-api-1-deploy --replicas=0
kubectl scale deployment -n python-api-1-dev python-api-1-deploy --replicas=1

# Opción 3: Usar annotate para forzar redeploy (manual)
kubectl annotate deployment -n python-api-1-dev python-api-1-deploy \
  kubectl.kubernetes.io/restartedAt=$(date +%Y-%m-%dT%H:%M:%S%z) --overwrite
```

**Alternativas para producción:**
1. **Reloader de Stakater**: Herramienta que monitorea cambios en ConfigMaps y Secrets y reinicia automáticamente los pods
2. **Montar ConfigMap como variables de entorno**: Los cambios se reflejan automáticamente (pero solo para variables simples)
3. **Sidecar de recarga**: Implementar un contenedor adicional que monitoree cambios y reinicie el contenedor principal
4. **Webhooks**: Configurar webhooks que detecten cambios en el repositorio y desencadenen reinicios

**Mejor Práctica**: Para entornos de producción, considera implementar **Reloader** o configurar un proceso de CI/CD que maneje automáticamente los reinicios cuando se detecten cambios en ConfigMaps.

## Gestión de ReplicaSets

### Limpieza de ReplicaSets antiguos

Kubernetes conserva los ReplicaSets antiguos para permitir rollbacks rápidos. Sin embargo, estos pueden acumularse y consumir recursos. Para limpiarlos:

```bash
# Ver todos los ReplicaSets (incluyendo los antiguos)
kubectl get replicasets -n python-api-1-dev

# Eliminar ReplicaSets antiguos (con 0 pods deseados)
kubectl delete replicaset -n python-api-1-dev $(kubectl get replicasets -n python-api-1-dev -o jsonpath='{.items[?(@.spec.replicas==0)].metadata.name}')

# Verificar que solo quede el ReplicaSet activo
kubectl get replicasets -n python-api-1-dev
```

### ¿Por qué se acumulan ReplicaSets?

1. **Historial de despliegues**: Cada vez que actualizas un deployment, Kubernetes crea un nuevo ReplicaSet
2. **Rolling updates**: Durante actualizaciones, Kubernetes mantiene temporalmente ambos ReplicaSets
3. **Rollback safety**: Permite volver rápidamente a versiones anteriores si hay problemas
4. **Configuración por defecto**: Kubernetes conserva hasta 10 revisiones (configurable en `.spec.revisionHistoryLimit`)

### Buenas prácticas

1. **Limitar el historial de revisiones** (en deployment.yaml):
```yaml
spec:
  revisionHistoryLimit: 3  # Conservar solo las últimas 3 revisiones
```

2. **Limpieza periódica** en entornos de desarrollo
3. **Monitorear ReplicaSets** para evitar acumulación excesiva

### Verificar estado actual

```bash
# Ver todos los recursos incluyendo ReplicaSets
kubectl get all -n python-api-1-dev

# Contar ReplicaSets antiguos (con 0 pods)
kubectl get replicasets -n python-api-1-dev --field-selector=status.replicas=0
```

### Staging

- **Namespace**: `python-api-1-staging`
- **Réplicas**: 2
- **Recursos**: 256Mi RAM / 250m CPU (requests), 512Mi / 500m (limits)
- **Variables**: `LOG_LEVEL=info`, `ENVIRONMENT=staging`

### Producción

- **Namespace**: `python-api-1-prod`
- **Réplicas**: 3
- **Recursos**: 512Mi RAM / 500m CPU (requests), 1Gi / 1000m (limits)
- **Variables**: `LOG_LEVEL=warn`, `ENVIRONMENT=production`

## Buenas Prácticas

### Gestión de Rollouts

1. **Usar `rollout restart` para reinicios controlados**: Preferir este método sobre eliminar pods directamente
2. **Monitorear el estado del rollout**: Usar `kubectl rollout status` para verificar que el despliegue se completa correctamente
3. **Limitar el historial de revisiones**: Configurar `revisionHistoryLimit` a 3-5 para evitar acumulación de ReplicaSets
4. **Verificar anotaciones**: Confirmar que los reinicios se registran correctamente con la anotación `restartedAt`

### Configuración Recomendada

Añadir esto a tus deployments para mejor control:

```yaml
spec:
  revisionHistoryLimit: 3  # Conservar solo las últimas 3 revisiones
  progressDeadlineSeconds: 600  # Tiempo máximo para completar el rollout
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1  # Máximo de pods adicionales durante el update
      maxUnavailable: 0  # Máximo de pods no disponibles durante el update
```

### Verificación

### Ver YAML Generado

```bash
# Desarrollo
kustomize build overlays/dev/python-api-1/

# Staging
kustomize build overlays/staging/python-api-1/

# Producción
kustomize build overlays/prod/python-api-1/
```

### Ver Eventos

```bash
kubectl get events -n python-api-1-dev --sort-by='.lastTimestamp'
```

## Comandos Útiles

### Verificar Recursos

```bash
kubectl get all -n python-api-1-dev
kubectl describe deployment -n python-api-1-dev python-api-1-deploy
```

### Ver Logs

```bash
# Ver logs en tiempo real con timestamps
kubectl logs -n python-api-1-dev -l app=python-api-1 --follow --timestamps=true

# Ver logs de todos los contenedores (si hay múltiples)
kubectl logs -n python-api-1-dev -l app=python-api-1 --all-containers=true --follow --timestamps=true

# Ver últimas 50 líneas con timestamps
kubectl logs -n python-api-1-dev -l app=python-api-1 --tail=50 --timestamps=true

# Ver logs de un pod específico (filtrar por nombre)
kubectl logs -n python-api-1-dev <nombre-del-pod> --follow --timestamps=true
```

### Escalar Aplicación

```bash
kubectl scale deployment -n python-api-1-dev python-api-1-deploy --replicas=3
```

### Eliminar Recursos

```bash
kubectl delete -k overlays/dev/python-api-1/
```

## Flujo de Trabajo

1. **Desarrollo**: Probar cambios en `python-api-1-dev`
2. **Staging**: Validar en `python-api-1-staging`
3. **Producción**: Desplegar en `python-api-1-prod`

```bash
# Ciclo completo
git pull origin main
# Hacer cambios en base/app-python-api-1/
cd overlays/dev/python-api-1
kustomize build . | kubectl apply -f -
# Verificar en dev
kubectl get pods -n python-api-1-dev -w
# Si todo bien, promover
cd ../../staging/python-api-1
kustomize build . | kubectl apply -f -
cd ../../prod/python-api-1
kustomize build . | kubectl apply -f -
```

## Ejemplo Práctico: Rollout Restart

### Caso de Uso: Actualizar ConfigMap y Reiniciar Pods

```bash
# 1. Actualizar el ConfigMap con el nuevo script Python
kubectl apply -f base/app-python-api-1/configmap.yaml

# 2. Verificar que el ConfigMap se actualizó
kubectl get configmap -n python-api-1-dev python-api-1-script -o yaml

# 3. Reiniciar el deployment para que los pods recojan los cambios
kubectl rollout restart deployment/python-api-1-deploy -n python-api-1-dev

# 4. Monitorear el estado del rollout
kubectl rollout status deployment/python-api-1-deploy -n python-api-1-dev

# 5. Verificar que los nuevos pods están corriendo
kubectl get pods -n python-api-1-dev

# 6. Verificar que los nuevos pods tienen los cambios
kubectl logs -n python-api-1-dev -l app=python-api-1 --tail=20

# 7. Verificar el historial de rollouts
kubectl rollout history deployment/python-api-1-deploy -n python-api-1-dev
```

### Verificación de Éxito

✅ **El pod se reinició**: El nombre del pod cambió y la edad es reciente
✅ **El deployment tiene nueva revisión**: `kubectl rollout history` muestra una nueva entrada
✅ **La anotación de restart está presente**: `kubectl describe deployment` muestra `kubectl.kubernetes.io/restartedAt`
✅ **La aplicación funciona**: Los logs muestran que el nuevo script se está ejecutando

### Rollback (si es necesario)

```bash
# Ver historial de revisiones
kubectl rollout history deployment/python-api-1-deploy -n python-api-1-dev

# Volver a una revisión anterior
kubectl rollout undo deployment/python-api-1-deploy -n python-api-1-dev --to-revision=2

# Verificar que el rollback se completó
kubectl rollout status deployment/python-api-1-deploy -n python-api-1-dev
```

## Notas Adicionales

### Advertencias de Seguridad

Al ejecutar `kubectl rollout restart`, es posible que veas advertencias de seguridad como:

```
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false
```

Estas advertencias indican que el pod no cumple con los estándares de seguridad modernos. Para corregirlas:

```yaml
# Añadir al deployment.yaml en la especificación del pod:
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

Si ves advertencias sobre `commonLabels` deprecated, actualiza tus archivos kustomization.yaml:

```bash
# Para cada directorio con kustomization.yaml
cd base/app-python-api-1
kustomize edit fix

cd ../../namespaces
kustomize edit fix
```

Esto convertirá automáticamente `commonLabels` a la sintaxis moderna `labels`.
