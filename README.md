# k8s-lab-gitops

GitOps repository for the Kubernetes Lab. This repository contains all declarative configurations for platform infrastructure and application workloads, managed by ArgoCD.

> **Prerequisite:** Ensure you have completed the cluster bootstrap following the [k8s-lab-infra installation guide](https://github.com/medaqueno/k8s-lab-infra).

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
│       └── overlays/       # Environment-specific configs (default)
│
└── apps/                   # Application workloads
    └── demo-app/           # Base manifests (single env)
```

## Quick Start

If you have completed the installation in `k8s-lab-infra`, ArgoCD is already installed and the bootstrap is applied. This repository manages:

1. **Platform components** (Istio, namespaces, gateways)
2. **Application workloads** (your applications in different environments)

### 1. Verify Platform Bootstrap
After applying the bootstrap in the Infra repository, ArgoCD will start synchronizing the platform.

**Check ArgoCD Applications Status:**
```bash
kubectl get applications -n argocd
```

| NAME | SYNC STATUS | HEALTH STATUS | DESCRIPTION |
| :--- | :--- | :--- | :--- |
| **bootstrap** | `Synced` | `Healthy` | The root app that manages everything else. |
| **platform** | `Synced` | `Progressing` | Installs Istio & System components. (See "Known Issues" below). |
| **workloads** | `Synced` | `Healthy` | Manages your demo applications. |

---

### 2. Access ArgoCD UI

1.  **Retrieve the admin password**:
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```

2.  **Port-forward to the server**:
    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

3.  **Login**: Open `https://localhost:8080` (User: `admin`).

---

### 3. Verify Istio Ambient Mesh
Ensure the mesh is active and running on your node(s):

```bash
kubectl get pods -n istio-system
```

You should see 1 instance of each component per node:
*   `ztunnel-xxxxx` (The sidecarless proxy)
*   `istiod-xxxxx` (Control Plane)
*   `istio-cni-node-xxxxx` (Network Interface Plugin)
*   `main-gateway-istio-xxxxx` (Ingress Gateway)

**Operational Check:**
Verify that `ztunnel` is capturing pods:
```bash
kubectl logs -n istio-system -l app=ztunnel | grep "adding pod"
```



---
   ```bash
   # Check ArgoCD applications
   kubectl get applications -n argocd
   
   # Check platform resources
   kubectl get namespaces
   kubectl get gateway -n istio-system
   
   # Check workloads
   kubectl get pods -n demo-app
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

1. **Create the application structure**:
   ```bash
   mkdir -p apps/my-api
   ```

2. **Create manifests** in `apps/my-api/`:
   
   **`namespace.yaml`:**
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: my-api
     labels:
       istio.io/dataplane-mode: ambient
       tier: application
   ```

   **`httproute.yaml`:**
   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: my-api-route
     namespace: my-api
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
   
   **`kustomization.yaml`:**
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - namespace.yaml
     - deployment.yaml
     - service.yaml
     - httproute.yaml
   ```

3. **Register the app** in `apps/kustomization.yaml`:
   ```yaml
   resources:
     # - demo-app # Example app (Commented out)
     - my-api     # Your new app
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add my-api application"
   git push
   ```

ArgoCD will automatically detect the new application.

### 2. Updating Configuration (ConfigMaps/Secrets)

#### Update a ConfigMap

1. **Edit the ConfigMap** in `apps/demo-app/configmap.yaml`:
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
   git add apps/demo-app/configmap.yaml
   git commit -m "Update demo-app config to v2.0"
   git push
   ```

3. **Verify sync**:
   ```bash
   kubectl get configmap -n demo-app demo-app-config -o yaml
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

### Application Status

```bash
# Check all applications
kubectl get applications -n argocd

# Get detailed info about a specific app
argocd app get workloads

# Check application logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### 1. "Platform" App stuck in `Progressing`
*   **Cause**: The Istio Ingress Gateway requests a `LoadBalancer` service. Since we don't have a Cloud Provider, the external IP remains `<pending>`.
*   **Impact**: ArgoCD waits for the IP to be assigned, so the app never reaches `Healthy`.
*   **Solution**: This is expected behavior. You can ignore it or:
    1. **Install MetalLB** to provide local IPs
    2. **Ignore Health Check**: Configure ArgoCD to ignore the `status.loadBalancer` field for Services.
    3. **Use NodePort**: Patch the generated Service to be `type: NodePort`.

### 2. Ztunnel Access Denied / FailedCreate
*   **Cause**: Istio Ambient's `ztunnel` needs to modify network tables on the host, requiring privileged access.
*   **Solution**: Ensure your namespace has the correct pod security label (handled by our configuration):
    ```yaml
    pod-security.kubernetes.io/enforce: privileged
    ```
This is already included in `platform/istio/base/namespace.yaml`.

### 3. Check Kustomize Build Locally
To verify the output before committing:
```bash
kustomize build apps/demo-app/overlays/dev
```

---

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [GitOps Principles](https://opengitops.dev/)
- [k8s-lab-infra Repository](https://github.com/medaqueno/k8s-lab-infra) - Initial cluster installation
- [Istio Ambient Mesh](https://istio.io/latest/docs/ambient/) - Sidecarless architecture
