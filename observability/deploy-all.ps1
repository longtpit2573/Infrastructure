# Deploy Complete Observability Stack
# Prometheus + Grafana + Loki + Tempo + Fluent Bit

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Deploying Observability Stack" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# Create namespace
Write-Host "`n[1/5] Creating monitoring namespace..." -ForegroundColor Yellow
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy Prometheus Stack
Write-Host "`n[2/5] Deploying Prometheus & Grafana..." -ForegroundColor Yellow
cd prometheus
powershell -ExecutionPolicy Bypass -File deploy.ps1
cd ..

# Wait for Prometheus to be ready
Write-Host "`nWaiting for Prometheus to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Deploy Loki
Write-Host "`n[3/5] Deploying Loki..." -ForegroundColor Yellow
cd loki
powershell -ExecutionPolicy Bypass -File deploy.ps1
cd ..

# Deploy Tempo
Write-Host "`n[4/5] Deploying Tempo..." -ForegroundColor Yellow
helm install tempo grafana/tempo `
  --namespace monitoring `
  --values tempo/values.yaml `
  --wait `
  --timeout 10m

# Deploy Fluent Bit
Write-Host "`n[5/5] Deploying Fluent Bit..." -ForegroundColor Yellow
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
helm install fluent-bit fluent/fluent-bit `
  --namespace monitoring `
  --values fluent-bit/values.yaml `
  --wait

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  ✅ Observability Stack Deployed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host "`n📊 Access Points:"
Write-Host "  Grafana: https://grafana.longops.io.vn"
Write-Host "    User: admin"
Write-Host "    Pass: Admin@123456"
Write-Host "`n  Prometheus: http://prometheus-kube-prometheus-prometheus.monitoring:9090"
Write-Host "  Loki: http://loki-gateway.monitoring.svc.cluster.local"
Write-Host "  Tempo: http://tempo.monitoring.svc.cluster.local:3100"

Write-Host "`n📝 Next Steps:"
Write-Host "  1. Configure DNS: grafana.longops.io.vn -> AKS Ingress IP"
Write-Host "  2. Add Loki datasource to Grafana"
Write-Host "  3. Add Tempo datasource to Grafana"
Write-Host "  4. Configure Gmail alerts (see prometheus/alertmanager-gmail-config.yaml)"
Write-Host "  5. Apply custom alert rules: kubectl apply -f prometheus/alert-rules.yaml"

Write-Host "`n🔍 Check Status:"
Write-Host "  kubectl get pods -n monitoring"
Write-Host "  kubectl get svc -n monitoring"
Write-Host "=========================================" -ForegroundColor Cyan
