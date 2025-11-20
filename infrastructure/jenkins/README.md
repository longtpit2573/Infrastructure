# Jenkins Deployment for FTM CI Pipeline

## 📁 Structure

```
Infrastructure/jenkins/
├── namespace.yaml           # Jenkins namespace
├── ingress.yaml            # Jenkins UI Ingress
├── jenkins-values.yaml     # Helm chart values (in ../scripts/)
└── README.md               # This file
```

## 🎯 Why Jenkins is NOT in ftm-gitops repo?

**ftm-gitops** = Application GitOps repo (managed by ArgoCD)
- Only contains FTM application manifests
- Backend and Frontend deployments
- ArgoCD monitors and syncs this repo

**Infrastructure/jenkins** = Infrastructure tooling (manual deployment)
- Jenkins itself is a tool, not the application
- Deployed once, not continuously synced
- Uses Helm for deployment

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────┐
│  Infrastructure (One-time setup)                   │
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌─────────────┐          ┌─────────────┐         │
│  │   ArgoCD    │          │   Jenkins   │         │
│  │   (CD)      │          │   (CI)      │         │
│  └──────┬──────┘          └──────┬──────┘         │
│         │                        │                │
│         │ monitors               │ updates        │
│         ▼                        ▼                │
│  ┌────────────────────────────────────┐           │
│  │      ftm-gitops repo               │           │
│  │  (Application manifests only)      │           │
│  └────────────────────────────────────┘           │
│         │                                          │
│         │ applies                                  │
│         ▼                                          │
│  ┌────────────────────────────────────┐           │
│  │   AKS Cluster (ftm-dev namespace)  │           │
│  │   - FTM Backend                    │           │
│  │   - FTM Frontend                   │           │
│  └────────────────────────────────────┘           │
│                                                    │
└────────────────────────────────────────────────────┘
```

## 🚀 Deployment

### Prerequisites
- AKS cluster running
- kubectl configured
- Helm 3 installed
- Nginx Ingress Controller deployed

### Deploy Jenkins

```powershell
cd E:\AKS-DEMO\Infrastructure\scripts
.\deploy-jenkins.ps1
```

This script:
1. Creates namespace from `../jenkins/namespace.yaml`
2. Installs Jenkins via Helm with `jenkins-values.yaml`
3. Applies Ingress from `../jenkins/ingress.yaml`

### Access Information

- **URL**: http://jenkins.longops.io.vn
- **Username**: admin
- **Password**: `Admin@123456` (⚠️ Change after first login!)

## ⚙️ Configuration Files

### Helm Values
Location: `../scripts/jenkins-values.yaml`

Key settings:
```yaml
controller:
  adminUser: admin
  adminPassword: Admin@123456
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
  persistence:
    enabled: true
    size: 20Gi
  installPlugins:
    - kubernetes
    - docker-workflow
    - git
    - pipeline
```

### Namespace
File: `namespace.yaml`
- Creates `jenkins` namespace
- Labeled for identification

### Ingress
File: `ingress.yaml`
- Exposes Jenkins at `jenkins.longops.io.vn`
- Uses Nginx Ingress Controller
- HTTP only (no SSL)

## 🔌 Post-Installation Steps

### 1. Add DNS Record
```
Host: jenkins.longops.io.vn
Type: A
Value: 4.144.199.99
```

### 2. Change Admin Password
1. Login to Jenkins UI
2. Admin → Configure
3. Update password
4. Save

### 3. Configure Credentials

Add these credentials in Jenkins:

**ACR Credentials**
```
Type: Username/Password
ID: acr-credentials
Username: acrftmbackenddev
Password: <from Azure Portal>
```

**GitHub PAT**
```
Type: Secret text
ID: github-pat
Secret: <your-github-token>
```

**Git Credentials**
```
Type: Username/Password
ID: git-credentials
Username: longtpit2573
Password: <github-pat>
```

**Kubeconfig**
```
Type: Secret file
ID: kubeconfig
File: ~/.kube/config
```

### 4. Create Pipelines

Create two pipelines:
- `ftm-backend-ci` - For FTM-BE repository
- `ftm-frontend-ci` - For FTM-FE repository

See `JENKINS_SETUP_GUIDE.md` for pipeline scripts.

## 🔄 CI/CD Workflow

```
1. Developer pushes code
   ↓
2. GitHub webhook triggers Jenkins
   ↓
3. Jenkins builds Docker image
   ↓
4. Jenkins pushes to ACR
   ↓
5. Jenkins updates ftm-gitops/overlays/dev/kustomization.yaml
   ↓
6. ArgoCD detects change (every 3 min)
   ↓
7. ArgoCD syncs new image to cluster
   ↓
8. K8s performs rolling update
   ↓
9. New pods running ✅
```

## 📊 Monitoring

```powershell
# Check Jenkins pod
kubectl get pods -n jenkins

# Check Jenkins logs
kubectl logs -f -n jenkins jenkins-0

# Check Ingress
kubectl get ingress -n jenkins

# Test access
curl -I http://jenkins.longops.io.vn
```

## 🔧 Troubleshooting

### Pod not starting
```powershell
kubectl describe pod jenkins-0 -n jenkins
kubectl get pvc -n jenkins
```

### Cannot access UI
```powershell
# Check service
kubectl get svc -n jenkins

# Check ingress
kubectl describe ingress jenkins-ingress -n jenkins

# Verify DNS
nslookup jenkins.longops.io.vn 8.8.8.8
```

### Credentials not working
```bash
# Get ACR credentials
az acr credential show --name acrftmbackenddev
```

## 📚 Documentation

- **JENKINS_SETUP_GUIDE.md**: Complete setup guide
- **Helm Chart**: https://github.com/jenkinsci/helm-charts
- **Jenkins Docs**: https://www.jenkins.io/doc/

## 🔗 Related Components

- **ArgoCD**: `../ftm-gitops/argocd/`
- **Application Manifests**: `../ftm-gitops/base/` and `../ftm-gitops/overlays/`
- **Scripts**: `../scripts/deploy-jenkins.ps1`

---

**Note**: Jenkins is infrastructure, not application. It should NOT be managed by ArgoCD or stored in ftm-gitops repo.
