# FTM GitOps Repository Structure

## 📁 Folder Organization

```
ftm-gitops/
├── applications/              # 🎯 Application Manifests (ArgoCD Auto-Sync)
│   ├── base/                 # Base Kustomize configurations
│   ├── backend/              # Backend base manifests
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── secrets.template.yaml
│   │
│   ├── frontend/             # Frontend base manifests
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   │
│   └── kustomization.yaml    # Base kustomization
│
├── overlays/                  # Environment-specific overlays
│   ├── dev/                  # Development environment
│   │   ├── kustomization.yaml
│   │   ├── replicas-patch.yaml
│   │   ├── ingress-patch.yaml
│   │   └── namespace.yaml
│   │
│   └── prod/                 # Production environment (future)
│       └── ...
│
├── scripts/                   # Utility scripts
│   └── create-backend-secrets.sh
│
├── .gitignore                # Ignore secrets
├── ARGOCD_USAGE_GUIDE.md     # How to use ArgoCD
└── README.md                 # This file
```

## 🎯 Purpose

This repository follows **GitOps principles**:
- Git is the single source of truth for **APPLICATION manifests**
- ArgoCD monitors this repo for changes
- All changes go through Git (no manual kubectl apply)
- Full audit trail via Git history

**⚠️ Important**: This repo contains ONLY application manifests (FTM Backend/Frontend).
Infrastructure tools (Jenkins, ArgoCD, monitoring) are deployed separately and NOT stored here.

## 🔄 Workflow

```
Developer → Git Push → Jenkins CI → Update Manifest → ArgoCD Sync → K8s Deploy
```

### CI Pipeline (Jenkins)
1. Developer pushes code to FTM-BE/FTM-FE
2. Jenkins builds Docker image
3. Jenkins pushes image to ACR
4. Jenkins updates image tag in this repo (`overlays/dev/kustomization.yaml`)
5. Jenkins commits and pushes to this repo

### CD Pipeline (ArgoCD)
1. ArgoCD detects change in this repo (every 3 minutes)
2. ArgoCD compares Git state vs Cluster state
3. If different, ArgoCD syncs (applies manifests)
4. Kubernetes performs rolling update
5. New pods deployed with new image

## 📂 Key Files

### ArgoCD Application
- **`argocd/app-dev.yaml`**: Defines how ArgoCD should deploy the dev environment
  - Points to `overlays/dev`
  - Auto-sync enabled
  - Deploys to `ftm-dev` namespace

### Kustomize Base
- **`base/`**: Shared configuration for all environments
  - Defines core resources (Deployment, Service, ConfigMap)
  - No environment-specific values

### Kustomize Overlays
- **`overlays/dev/`**: Development environment customization
  - Sets namespace to `ftm-dev`
  - Configures 1 replica (cost optimization)
  - Sets image tags (updated by Jenkins)
  - Configures Ingress host

## 🔐 Secrets Management

**❌ Never commit secrets to Git!**

Secrets are managed outside of Git:
```bash
# Create secrets directly in cluster
kubectl create secret generic ftm-backend-secrets \
  --from-literal=JWT_ISSUER="..." \
  -n ftm-dev
```

Files with `.template.yaml` suffix are examples only.

## 🚀 Deployment Process

### Initial Setup
1. ArgoCD deployed to cluster
2. ArgoCD Application created (`argocd/app-dev.yaml`)
3. Secrets created in cluster (not in Git)
4. ArgoCD syncs and deploys application

### Continuous Deployment
1. Code change pushed to FTM-BE/FTM-FE repo
2. Jenkins builds and pushes new image
3. Jenkins updates `overlays/dev/kustomization.yaml`:
   ```yaml
   images:
     - name: ftm-backend
       newTag: abc1234-15  # Updated by Jenkins
   ```
4. Jenkins commits and pushes to this repo
5. ArgoCD detects change and syncs
6. New pods deployed automatically

## 🔧 Local Testing

Test Kustomize build before committing:

```bash
# Build manifests for dev environment
kustomize build overlays/dev

# Validate with kubectl
kustomize build overlays/dev | kubectl apply --dry-run=client -f -
```

## 📊 Monitoring

### Check ArgoCD Application Status
```bash
kubectl get application ftm-dev -n argocd
argocd app get ftm-dev
```

### Check Deployed Resources
```bash
kubectl get all -n ftm-dev
```

### View Sync History
```bash
argocd app history ftm-dev
```

## 🔄 Rollback

### Via ArgoCD
```bash
# View history
argocd app history ftm-dev

# Rollback to specific revision
argocd app rollback ftm-dev <revision>
```

### Via Git
```bash
# Revert commit
git revert <commit-hash>
git push

# ArgoCD will auto-sync to reverted state
```

## 📚 Documentation

- **ARGOCD_USAGE_GUIDE.md**: Comprehensive ArgoCD usage guide
- **argocd/README.md**: ArgoCD-specific notes
- **jenkins/README.md**: Jenkins deployment notes

## 🏷️ Branches

- **main**: Production-ready manifests (auto-deployed by ArgoCD)

## 👥 Contributors

- Infrastructure Team
- DevOps Engineers

## 🔗 Related Repositories

- **Application Code**: 
  - https://github.com/longtpit2573/FTM-BE
  - https://github.com/longtpit2573/FTM-FE
- **Terraform Infrastructure**: `../Terraform/`

---

*Last updated: November 2025*
