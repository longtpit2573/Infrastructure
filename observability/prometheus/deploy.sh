#!/bin/bash

# Deploy Prometheus Stack for AKS Observability
# This script deploys kube-prometheus-stack with Grafana, Alertmanager

set -e

echo "========================================="
echo "  Deploying Prometheus Stack"
echo "========================================="

# Add Prometheus Community Helm repo
echo "Adding prometheus-community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy kube-prometheus-stack
echo "Deploying kube-prometheus-stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml \
  --wait \
  --timeout 10m

echo ""
echo "========================================="
echo "  ✅ Prometheus Stack Deployed"
echo "========================================="
echo ""
echo "Components deployed:"
echo "  - Prometheus Operator"
echo "  - Prometheus Server"
echo "  - Grafana"
echo "  - Alertmanager"
echo "  - Node Exporter"
echo "  - Kube State Metrics"
echo ""
echo "Access Grafana:"
echo "  URL: https://grafana.longops.io.vn"
echo "  Username: admin"
echo "  Password: Admin@123456"
echo ""
echo "Check status:"
echo "  kubectl get pods -n monitoring"
echo "  kubectl get svc -n monitoring"
echo ""
echo "Next steps:"
echo "  1. Configure DNS for grafana.longops.io.vn"
echo "  2. Setup Loki for logs"
echo "  3. Setup Tempo for traces"
echo "  4. Configure alerts"
echo "========================================="
