# Deploy Loki for Log Aggregation

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Deploying Grafana Loki" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Add Grafana Helm repo
Write-Host "`nAdding Grafana Helm repository..." -ForegroundColor Yellow
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy Loki
Write-Host "`nDeploying Loki..." -ForegroundColor Yellow
helm install loki grafana/loki `
  --namespace monitoring `
  --values values.yaml `
  --wait `
  --timeout 10m

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  ✅ Loki Deployed" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "`nLoki endpoint: http://loki-gateway.monitoring.svc.cluster.local"
Write-Host "`nAdd to Grafana datasource:"
Write-Host "  Name: Loki"
Write-Host "  Type: Loki"
Write-Host "  URL: http://loki-gateway.monitoring.svc.cluster.local"
Write-Host "=========================================" -ForegroundColor Cyan
