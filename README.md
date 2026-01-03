# k8s-lab-gitops

GitOps repository for the Kubernetes Lab. This repository contains all declarative configurations for platform infrastructure and application workloads, managed by ArgoCD.

## 📁 Repository Structure

```
k8s-lab-gitops/
├── bootstrap/              # Entry point - "App of Apps"
│   ├── bootstrap.yaml      # Main bootstrap application
│   └── argocd-apps/        # ArgoCD Application definitions
│       ├── platform.yaml   # Syncs platform/ directory
│       └── workloads.yaml  # Syncs apps/ directory
│
├── platform/               # Cluster-wide infrastructure
│   └── istio/
│       ├── base/           # Istio Gateway and namespace
│       └── overlays/       # Environment-specific configs
│
└── apps/                   # Application workloads
    └── demo-app/
        ├── base/           # Base manifests (env-agnostic)
        └── overlays/       # Environment-specific configs
            ├── dev/
            └── prod/
```

## 🚀 Initial Setup

### Prerequisites
- Kubernetes cluster running (see `k8s-lab-infra` for cluster setup)
- `kubectl` configured to access the cluster

### Bootstrap the GitOps System

1. **Install ArgoCD**:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Apply the Bootstrap Application**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/medaqueno/k8s-lab-gitops/main/bootstrap/bootstrap.yaml
   ```

3. **Verify Deployment**:
   ```bash
   # Check ArgoCD applications
   kubectl get applications -n argocd
   
   # Check platform resources
   kubectl get namespaces
   kubectl get gateway -n istio-system
   
   # Check workloads
   kubectl get pods -n dev-demo-app
   ```

## 🌐 Accessing Applications
The applications are exposed via the Istio Ingress Gateway using NodePorts (unless MetalLB is configured).

### 1. Find the Cluster Node IP
This is the address of your physical/virtual machine running the cluster.
```bash
kubectl get nodes -o wide
# Look for INTERNAL-IP (e.g., 192.168.1.35)
```

### 2. Find the Gateway NodePort
This is the specific port opened on that node for HTTP traffic.
```bash
kubectl get svc -n istio-system main-gateway-istio
# Look for PORT(S) -> 80:30613/TCP. The second number (30613) is the NodePort.
```

### 3. Access URL
Combine the IP and Port:
`http://<NODE-IP>:<NODE-PORT>/`

Example: `http://192.168.1.35:30613/`

## 📘 Common Use Cases

### 1. Adding a New Application

To add a new application (e.g., `my-api`):

1. **Apply the Landing Zone (Recommended)**:
   By default, ArgoCD can create namespaces, but it creates them without labels. For Istio Ambient Mesh to work, the namespace *must* have the correct label.
   
   Create a namespace manifest (e.g., `apps/my-api/base/namespace.yaml`):
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: dev-my-api
     labels:
       istio.io/dataplane-mode: ambient
       tier: application
   ```
   *Note: You can also choose to add this to a central `platform` folder if you prefer global management.*

2. **Create the application structure**:
   ```bash
   mkdir -p apps/my-api/{base,overlays/{dev,prod}}
   ```

2. **Create base manifests** in `apps/my-api/base/`:
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - namespace.yaml
     - deployment.yaml
     - service.yaml
     - configmap.yaml
     - httproute.yaml
   ```

4. **Create HTTPRoute** in `apps/my-api/base/httproute.yaml` to expose it via Istio:
   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: my-api-route
     namespace: dev-my-api
   spec:
     parentRefs:
       - name: main-gateway
         namespace: istio-system
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /my-api
         filters:
           - type: URLRewrite
             urlRewrite:
               path:
                 type: ReplacePrefixMatch
                 replacePrefixMatch: /
         backendRefs:
           - name: my-api
             port: 80
   ```

5. **Create environment overlays** in `apps/my-api/overlays/dev/`:
   Ensure the `namespace` field matches the one created in step 1.
   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   bases:
     - ../../base
   namespace: dev-my-api
   commonLabels:
     environment: dev
   ```

6. **Register the app** in `apps/kustomization.yaml`:
   ```yaml
   resources:
     - demo-app/base/kustomization.yaml
     - my-api/base/kustomization.yaml  # Add this line
   ```

7. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add my-api application and its landing zone"
   git push
   ```

ArgoCD will automatically detect the new namespace and the application.

### 2. Deploying to Different Environments

#### Deploy to Development
The `dev` overlay is automatically synced by the `workloads` Application. Just push changes to the `main` branch.

#### Deploy to Production
To deploy to production, you have two options:

**Option A: Separate ArgoCD Application (Recommended)**

Create `bootstrap/argocd-apps/workloads-prod.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: workloads-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/medaqueno/k8s-lab-gitops.git
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: false  # Manual approval for prod
```

**Option B: Use Kustomize Overlays**

Modify your app's overlay to point to `prod`:
```bash
# In apps/my-api/overlays/prod/kustomization.yaml
namespace: prod-my-api
commonLabels:
  environment: prod
replicas:
  - name: my-api
    count: 3
```

### 3. Updating Configuration (ConfigMaps/Secrets)

#### Update a ConfigMap

1. **Edit the ConfigMap** in `apps/demo-app/base/configmap.yaml`:
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: demo-app-config
   data:
     app.properties: |
       version=2.0  # Changed from 1.0
       feature.enabled=true  # New property
   ```

2. **Commit and push**:
   ```bash
   git add apps/demo-app/base/configmap.yaml
   git commit -m "Update demo-app config to v2.0"
   git push
   ```

3. **Verify sync**:
   ```bash
   kubectl get configmap -n dev-demo-app demo-app-config -o yaml
   ```

#### Add a Secret

1. **Create the secret manifest** in `apps/my-api/base/secret.yaml`:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: my-api-secret
   type: Opaque
   stringData:
     database-password: "changeme"  # Use sealed-secrets in production!
   ```

2. **Add to kustomization**:
   ```yaml
   # apps/my-api/base/kustomization.yaml
   resources:
     - deployment.yaml
     - service.yaml
     - secret.yaml  # Add this
   ```

> [!WARNING]
> **Never commit real secrets to Git!** Use [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) or [External Secrets Operator](https://external-secrets.io/) for production.

### 4. Rolling Back Changes

#### Option A: Git Revert (Recommended)

1. **Find the commit to revert**:
   ```bash
   git log --oneline apps/demo-app/
   ```

2. **Revert the commit**:
   ```bash
   git revert <commit-hash>
   git push
   ```

ArgoCD will automatically sync the reverted state.

#### Option B: Manual Rollback via ArgoCD UI

1. Access ArgoCD UI:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. Navigate to the application → **History and Rollback** → Select previous revision → **Rollback**.

#### Option C: Disable Auto-Sync and Rollback Manually

1. **Disable auto-sync** in the Application manifest:
   ```yaml
   syncPolicy:
     automated: null  # Remove automated sync
   ```

2. **Manually sync to a previous revision**:
   ```bash
   argocd app rollback workloads <revision-number>
   ```

### 5. Adding Platform Components

To add a new platform component (e.g., monitoring):

1. **Create the structure**:
   ```bash
   mkdir -p platform/monitoring/{base,overlays/dev}
   ```

2. **Add manifests** in `platform/monitoring/base/`:
   ```yaml
   # namespace.yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: monitoring
     labels:
       app.kubernetes.io/part-of: platform
       istio.io/dataplane-mode: ambient  # If this tool should be in the mesh
   ```

3. **Register in platform kustomization**:
   ```yaml
   # platform/kustomization.yaml
   resources:
     - istio/base/kustomization.yaml
     - monitoring/base/kustomization.yaml  # Add this
   ```

4. **Commit and push**:
   ```bash
   git add platform/monitoring
   git commit -m "Add monitoring platform component"
   git push
   ```

## 🔍 Troubleshooting

### Check Application Status
```bash
kubectl get applications -n argocd
argocd app get workloads
```

### Application stays in "Progressing" (LoadBalancer Pending)

In local environments without a cloud provider (like this lab), the Istio Gateway creates a Service of type `LoadBalancer` that will stay in `<pending>` status because there's no automatic IP provisioner.

**Options to fix this:**
1. **MetalLB (Recommended)**: Install [MetalLB](https://metallb.universe.tf/) in the cluster to provide local IP addresses.
2. **Ignore Health Check**: Configure ArgoCD to ignore the `status.loadBalancer` field for Services.
3. **Use NodePort**: Patch the generated Service to be `type: NodePort`.

### Ztunnel pods not starting

Istio Ambient's `ztunnel` requires privileged permissions. Ensure the `istio-system` namespace has the following label:
```yaml
pod-security.kubernetes.io/enforce: privileged
```
This is already included in `platform/istio/base/namespace.yaml`.

### Check Kustomize Build Locally
```bash
kustomize build apps/demo-app/overlays/dev
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [GitOps Principles](https://opengitops.dev/)
- [k8s-lab-infra Repository](https://github.com/medaqueno/k8s-lab-infra) - Cluster infrastructure setup
