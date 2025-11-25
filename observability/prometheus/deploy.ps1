# Deploy Prometheus Stack for AKS Observability
# This script deploys kube-prometheus-stack with Grafana, Alertmanager

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Deploying Prometheus Stack" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Add Prometheus Community Helm repo
Write-Host "`nAdding prometheus-community Helm repository..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
Write-Host "`nCreating monitoring namespace..." -ForegroundColor Yellow
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy kube-prometheus-stack
Write-Host "`nDeploying kube-prometheus-stack..." -ForegroundColor Yellow
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --values values.yaml `
  --wait `
  --timeout 10m

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  ✅ Prometheus Stack Deployed" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "`nComponents deployed:"
Write-Host "  - Prometheus Operator"
Write-Host "  - Prometheus Server"
Write-Host "  - Grafana"
Write-Host "  - Alertmanager"
Write-Host "  - Node Exporter"
Write-Host "  - Kube State Metrics"
Write-Host "`nAccess Grafana:"
Write-Host "  URL: https://grafana.longops.io.vn"
Write-Host "  Username: admin"
Write-Host "  Password: Admin@123456"
Write-Host "`nCheck status:"
Write-Host "  kubectl get pods -n monitoring"
Write-Host "  kubectl get svc -n monitoring"
Write-Host "`nNext steps:"
Write-Host "  1. Configure DNS for grafana.longops.io.vn"
Write-Host "  2. Setup Loki for logs"
Write-Host "  3. Setup Tempo for traces"
Write-Host "  4. Configure alerts"
Write-Host "=========================================" -ForegroundColor Cyan
