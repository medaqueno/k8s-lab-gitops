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

### Forzar Redespliegue

```bash
# Eliminar y volver a crear
kubectl delete -k overlays/dev/python-api-1/
kustomize build overlays/dev/python-api-1/ | kubectl apply -f -
```

## Configuración por Entorno

### Desarrollo

- **Namespace**: `python-api-1-dev`
- **Réplicas**: 1
- **Recursos**: Sin límites
- **Variables**: `LOG_LEVEL=debug`, `ENVIRONMENT=development`

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

## Verificación

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
