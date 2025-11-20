# Script deploy ArgoCD và expose UI qua Ingress
# Location: E:\AKS-DEMO\Infrastructure\ftm-gitops\scripts\deploy-argocd.ps1

Write-Host "🚀 Deploying ArgoCD to AKS..." -ForegroundColor Cyan

# Step 1: Create ArgoCD namespace
Write-Host "`n📦 Step 1: Creating argocd namespace..." -ForegroundColor Yellow
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Install ArgoCD
Write-Host "`n📥 Step 2: Installing ArgoCD..." -ForegroundColor Yellow
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
Write-Host "`n⏳ Step 3: Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Step 4: Get admin password
Write-Host "`n🔑 Step 4: Getting ArgoCD admin password..." -ForegroundColor Yellow
$adminPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "Admin Password: $adminPassword" -ForegroundColor Green
Write-Host "⚠️  SAVE THIS PASSWORD! You'll need it to login." -ForegroundColor Red

# Step 5: Create Ingress for ArgoCD UI
Write-Host "`n🌐 Step 5: Creating Ingress for ArgoCD UI..." -ForegroundColor Yellow

$ingressYaml = @"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.longops.io.vn
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
"@

$ingressYaml | kubectl apply -f -

# Step 6: Get Ingress IP
Write-Host "`n📡 Step 6: Getting Ingress External IP..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
$ingressIP = kubectl get ingress argocd-server-ingress -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

if ($ingressIP) {
    Write-Host "Ingress IP: $ingressIP" -ForegroundColor Green
} else {
    Write-Host "⏳ Ingress IP is pending... Check later with:" -ForegroundColor Yellow
    Write-Host "kubectl get ingress -n argocd" -ForegroundColor Cyan
}

# Step 7: Apply ArgoCD Project and Applications
Write-Host "`n📋 Step 7: Applying ArgoCD Project and Applications..." -ForegroundColor Yellow

$gitopsPath = "E:\AKS-DEMO\Infrastructure\ftm-gitops\argocd"

if (Test-Path "$gitopsPath\project.yaml") {
    kubectl apply -f "$gitopsPath\project.yaml"
    Write-Host "✅ Project applied" -ForegroundColor Green
} else {
    Write-Host "❌ project.yaml not found" -ForegroundColor Red
}

if (Test-Path "$gitopsPath\app-dev.yaml") {
    kubectl apply -f "$gitopsPath\app-dev.yaml"
    Write-Host "✅ Dev application applied" -ForegroundColor Green
} else {
    Write-Host "❌ app-dev.yaml not found" -ForegroundColor Red
}

if (Test-Path "$gitopsPath\app-prod.yaml") {
    kubectl apply -f "$gitopsPath\app-prod.yaml"
    Write-Host "✅ Production application applied" -ForegroundColor Green
} else {
    Write-Host "❌ app-prod.yaml not found" -ForegroundColor Red
}

# Summary
Write-Host "`n✅ ArgoCD Deployment Complete!" -ForegroundColor Green
Write-Host "`n📊 Access ArgoCD UI:" -ForegroundColor Cyan
Write-Host "   URL: http://argocd.longops.io.vn" -ForegroundColor White
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: $adminPassword" -ForegroundColor White
Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Add DNS record: argocd.longops.io.vn → $ingressIP" -ForegroundColor White
Write-Host "   2. Open browser: http://argocd.longops.io.vn" -ForegroundColor White
Write-Host "   3. Login with credentials above" -ForegroundColor White
Write-Host "   4. View applications in UI dashboard" -ForegroundColor White
Write-Host "`n🔧 Useful Commands:" -ForegroundColor Cyan
Write-Host "   kubectl get pods -n argocd" -ForegroundColor White
Write-Host "   kubectl get applications -n argocd" -ForegroundColor White
Write-Host "   kubectl logs -n argocd deployment/argocd-server" -ForegroundColor White
Write-Host "   kubectl get ingress -n argocd" -ForegroundColor White
