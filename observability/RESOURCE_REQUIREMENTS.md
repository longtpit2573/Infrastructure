# Resource Requirements for Observability Stack

## Current Setup

### Standard_B2s (2 vCPU, 4GB RAM) - **NOT SUFFICIENT**
- Jenkins: ~1GB RAM
- ArgoCD: ~500MB RAM
- FTM Backend + Frontend: ~512MB RAM
- **Total Used: ~2GB / 2.8GB available**
- **Result**: No room for Prometheus + Loki + Tempo

### Standard_B4ms (4 vCPU, 16GB RAM) - **RECOMMENDED**
- Jenkins: ~1GB RAM
- ArgoCD: ~500MB RAM
- Applications: ~1GB RAM
- Prometheus Stack: ~2GB RAM
- Loki: ~1GB RAM
- Tempo: ~512MB RAM
- Fluent Bit: ~200MB RAM
- **Total: ~6.2GB / 15GB available** ✅

## Resource Allocation per Component

### Prometheus Stack (kube-prometheus-stack)
```yaml
Prometheus Server:
  requests: 256Mi CPU, 512Mi RAM
  limits: 500m CPU, 1Gi RAM

Grafana:
  requests: 100m CPU, 256Mi RAM
  limits: 500m CPU, 512Mi RAM

Alertmanager:
  requests: 50m CPU, 128Mi RAM
  limits: 200m CPU, 256Mi RAM

Node Exporter (per node):
  requests: 50m CPU, 64Mi RAM
  limits: 200m CPU, 128Mi RAM

Kube State Metrics:
  requests: 50m CPU, 128Mi RAM
  limits: 200m CPU, 256Mi RAM

Prometheus Operator:
  requests: 100m CPU, 128Mi RAM
  limits: 200m CPU, 256Mi RAM

Total: ~650m CPU, ~1.2Gi RAM
```

### Loki (Single Binary Mode)
```yaml
Loki Server:
  requests: 100m CPU, 256Mi RAM
  limits: 500m CPU, 512Mi RAM

Gateway:
  requests: 50m CPU, 64Mi RAM
  limits: 200m CPU, 128Mi RAM

Total: ~150m CPU, ~320Mi RAM
```

### Tempo
```yaml
Tempo Server:
  requests: 100m CPU, 256Mi RAM
  limits: 500m CPU, 512Mi RAM

Gateway:
  requests: 50m CPU, 64Mi RAM
  limits: 200m CPU, 128Mi RAM

Total: ~150m CPU, ~320Mi RAM
```

### Fluent Bit (DaemonSet - per node)
```yaml
  requests: 50m CPU, 64Mi RAM
  limits: 200m CPU, 128Mi RAM
```

## Scaling Recommendations

### For Production (3 nodes)
- **VM Size**: Standard_D4s_v3 (4 vCPU, 16GB RAM each)
- **Node Count**: 3 nodes minimum
- **Total**: 12 vCPU, 48GB RAM
- **Cost**: ~$350/month

### For Demo/Dev (1 node)
- **VM Size**: Standard_B4ms (4 vCPU, 16GB RAM)
- **Node Count**: 1 node
- **Total**: 4 vCPU, 16GB RAM
- **Cost**: ~$120/month

### Minimal Setup (1 node) - Current
- **VM Size**: Standard_B2s (2 vCPU, 4GB RAM)
- **Components**: Jenkins + ArgoCD + Apps only
- **No Observability Stack**
- **Cost**: ~$30/month

## Migration Steps

### 1. Add New Node Pool
```bash
az aks nodepool add \
  --resource-group rg-ftm-aks-dev \
  --cluster-name aks-ftm-dev \
  --name pool2 \
  --node-count 1 \
  --node-vm-size Standard_B4ms \
  --max-pods 110 \
  --mode User
```

### 2. Cordon Old Node
```bash
kubectl cordon aks-workerpool-52068604-vmss000003
```

### 3. Drain Workloads
```bash
kubectl drain aks-workerpool-52068604-vmss000003 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=300
```

### 4. Delete Old Node Pool
```bash
az aks nodepool delete \
  --resource-group rg-ftm-aks-dev \
  --cluster-name aks-ftm-dev \
  --name workerpool
```

### 5. Deploy Observability Stack
```powershell
cd Infrastructure/observability
powershell -ExecutionPolicy Bypass -File deploy-all.ps1
```

## Cost Comparison

| Setup | VM Size | Nodes | vCPU | RAM | Monthly Cost |
|-------|---------|-------|------|-----|--------------|
| Minimal | B2s | 1 | 2 | 4GB | ~$30 |
| Dev | B4ms | 1 | 4 | 16GB | ~$120 |
| Production | D4s_v3 | 3 | 12 | 48GB | ~$350 |

## Storage Requirements

### PersistentVolumes
- Prometheus: 10Gi (7 days retention)
- Loki: 10Gi (7 days retention)
- Tempo: 10Gi (7 days retention)
- Grafana: 5Gi (dashboards)
- Alertmanager: 2Gi (alerts)

**Total Storage**: ~40Gi managed disks (~$8/month)

## Optimization Tips

### For B2s Nodes (Current)
1. **Disable Observability Stack**
2. Use external monitoring (Azure Monitor)
3. Minimal Jenkins resources
4. Single replica for all services

### For B4ms Nodes (Recommended)
1. ✅ Full Prometheus + Grafana + Loki + Tempo
2. ✅ 7-day retention
3. ✅ Multiple replicas for HA
4. ✅ ServiceMonitors for all apps

### For Production
1. Node autoscaling (1-5 nodes)
2. Pod autoscaling (HPA)
3. Long-term storage with Thanos
4. Multi-zone deployment
5. Dedicated node pools (system vs user)
