# Comandos útiles para k8s-lab-gitops

## Setup inicial

# 1. Crear todos los namespaces
kubectl apply -k base/namespaces/

# 2. Verificar namespaces creados
kubectl get namespaces -l lab-group=k8s-lab


## Despliegues por entorno

# DEV
kubectl apply -k overlays/dev/python-api-1/
kubectl get all -n python-api-1-dev
kubectl logs -n python-api-1-dev -l app=python-api-1 -f

# STAGING
kubectl apply -k overlays/staging/python-api-1/
kubectl get all -n python-api-1-staging
kubectl logs -n python-api-1-staging -l app=python-api-1 -f

# PROD
kubectl apply -k overlays/prod/python-api-1/
kubectl get all -n python-api-1-prod
kubectl logs -n python-api-1-prod -l app=python-api-1 -f


## Ver YAML generado sin aplicar

kubectl kustomize overlays/dev/python-api-1/
kubectl kustomize overlays/staging/python-api-1/
kubectl kustomize overlays/prod/python-api-1/


## Ver diferencias antes de aplicar

kubectl diff -k overlays/dev/python-api-1/
kubectl diff -k overlays/staging/python-api-1/
kubectl diff -k overlays/prod/python-api-1/


## Debugging

# Ver eventos de un namespace
kubectl get events -n python-api-1-dev --sort-by='.lastTimestamp'

# Describir un deployment
kubectl describe deployment -n python-api-1-dev python-api-1-deploy

# Ver configuración de un pod
kubectl get pod -n python-api-1-dev -l app=python-api-1 -o yaml

# Ejecutar shell en un pod
kubectl exec -it -n python-api-1-dev -l app=python-api-1 -- /bin/bash

# Ver variables de entorno de un pod
kubectl exec -n python-api-1-dev -l app=python-api-1 -- env | sort


## Limpieza

# Eliminar deployment de un entorno
kubectl delete -k overlays/dev/python-api-1/

# Eliminar todos los namespaces
kubectl delete -k base/namespaces/


## Verificar recursos por entorno

# Ver replicas configuradas
kubectl get deployment -n python-api-1-dev python-api-1-deploy -o jsonpath='{.spec.replicas}'
kubectl get deployment -n python-api-1-staging python-api-1-deploy -o jsonpath='{.spec.replicas}'
kubectl get deployment -n python-api-1-prod python-api-1-deploy -o jsonpath='{.spec.replicas}'

# Ver recursos configurados
kubectl get deployment -n python-api-1-dev python-api-1-deploy -o jsonpath='{.spec.template.spec.containers[0].resources}'
kubectl get deployment -n python-api-1-staging python-api-1-deploy -o jsonpath='{.spec.template.spec.containers[0].resources}'
kubectl get deployment -n python-api-1-prod python-api-1-deploy -o jsonpath='{.spec.template.spec.containers[0].resources}'


## Monitorización

# Ver consumo de recursos por namespace
kubectl top pods -n python-api-1-dev
kubectl top pods -n python-api-1-staging
kubectl top pods -n python-api-1-prod

# Ver todos los recursos en todos los namespaces de la app
kubectl get all -A -l app=python-api-1


## Workflow típico de desarrollo

# 1. Hacer cambios en base/app-python-api-1/
# 2. Verificar YAML generado
kubectl kustomize overlays/dev/python-api-1/

# 3. Aplicar en dev para testing
kubectl apply -k overlays/dev/python-api-1/

# 4. Verificar que funciona
kubectl get pods -n python-api-1-dev -w

# 5. Ver logs
kubectl logs -n python-api-1-dev -l app=python-api-1 -f

# 6. Si funciona, aplicar en staging
kubectl apply -k overlays/staging/python-api-1/

# 7. Verificar staging
kubectl get pods -n python-api-1-staging -w

# 8. Si todo OK, aplicar en prod
kubectl apply -k overlays/prod/python-api-1/
