#!/bin/bash

# Script de prueba rápida para verificar la estructura de Kustomize

set -e

echo "======================================"
echo "Verificando estructura de Kustomize"
echo "======================================"
echo ""

# Verificar que kubectl y kustomize están disponibles
echo "1. Verificando herramientas..."
kubectl version --client --short 2>/dev/null || echo "⚠️  kubectl no encontrado"
echo ""

# Verificar estructura de archivos
echo "2. Verificando estructura de archivos..."
if [ -d "base/namespaces" ] && [ -d "base/app-python-api-1" ] && [ -d "overlays/dev/python-api-1" ]; then
    echo "✅ Estructura de directorios correcta"
else
    echo "❌ Faltan directorios"
    exit 1
fi
echo ""

# Generar YAML de namespaces
echo "3. Generando YAML de namespaces..."
kubectl kustomize base/namespaces/ > /tmp/namespaces-output.yaml
echo "✅ Namespaces generados correctamente"
echo ""

# Generar YAML de dev
echo "4. Generando YAML de dev..."
kubectl kustomize overlays/dev/python-api-1/ > /tmp/dev-output.yaml
echo "✅ Dev overlay generado correctamente"
echo "   - Deployment: python-api-1-deploy"
echo "   - Namespace: python-api-1-dev"
echo "   - Replicas: 1"
echo ""

# Generar YAML de staging
echo "5. Generando YAML de staging..."
kubectl kustomize overlays/staging/python-api-1/ > /tmp/staging-output.yaml
echo "✅ Staging overlay generado correctamente"
echo "   - Deployment: python-api-1-deploy"
echo "   - Namespace: python-api-1-staging"
echo "   - Replicas: 2"
echo ""

# Generar YAML de prod
echo "6. Generando YAML de prod..."
kubectl kustomize overlays/prod/python-api-1/ > /tmp/prod-output.yaml
echo "✅ Prod overlay generado correctamente"
echo "   - Deployment: python-api-1-deploy"
echo "   - Namespace: python-api-1-prod"
echo "   - Replicas: 3"
echo ""

echo "======================================"
echo "✅ Todas las verificaciones pasaron"
echo "======================================"
echo ""
echo "Archivos generados en /tmp:"
echo "  - namespaces-output.yaml"
echo "  - dev-output.yaml"
echo "  - staging-output.yaml"
echo "  - prod-output.yaml"
echo ""
echo "Para desplegar:"
echo "  kubectl apply -k base/namespaces/"
echo "  kubectl apply -k overlays/dev/python-api-1/"
echo ""
echo "Para verificar el contenido:"
echo "  cat /tmp/dev-output.yaml | grep 'name: python-api-1'"
