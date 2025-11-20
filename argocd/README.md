# ArgoCD Configuration

## 📁 Files in this directory

- **`app-dev.yaml`**: ArgoCD Application for dev environment
- **`project.yaml`**: ArgoCD Project with RBAC roles
- **`ingress.yaml`**: Exposes ArgoCD UI at http://argocd.longops.io.vn

## 🚀 Deployment

ArgoCD is deployed in the `argocd` namespace:

```bash
# Apply ArgoCD installation
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply custom ingress
kubectl apply -f ingress.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 🌐 Access

- **URL**: http://argocd.longops.io.vn
- **Username**: admin
- **Password**: `lmwA4QsIuLV-wJMa`

## 📋 Applications

### ftm-dev

Deploys the FTM application to dev environment:

```yaml
Source:
  Repo: https://github.com/longtpit2573/ftm-gitops.git
  Path: overlays/dev
  
Destination:
  Server: https://kubernetes.default.svc
  Namespace: ftm-dev
  
Sync Policy:
  Automated: true
  Prune: true
  SelfHeal: true
```

## 🔧 Configuration

### Insecure Mode

ArgoCD is configured to run in insecure mode (HTTP) for internal use:

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
```

This allows the Ingress to use HTTP without SSL termination.

## 📖 Documentation

See **ARGOCD_USAGE_GUIDE.md** in parent directory for detailed usage instructions.
