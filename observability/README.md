# Observability Stack for AKS

Complete monitoring, logging, and tracing solution for the FTM application on Azure Kubernetes Service.

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Grafana Dashboard                       │
│  (Visualization & Alerting: grafana.longops.io.vn)         │
└───────────┬──────────────┬──────────────┬───────────────────┘
            │              │              │
            ▼              ▼              ▼
    ┌───────────┐  ┌──────────┐  ┌────────────┐
    │Prometheus │  │   Loki   │  │   Tempo    │
    │ (Metrics) │  │  (Logs)  │  │ (Traces)   │
    └─────┬─────┘  └────┬─────┘  └──────┬─────┘
          │             │                │
          ▼             ▼                ▼
    ┌─────────┐  ┌──────────┐  ┌──────────────┐
    │ Thanos  │  │  Kafka   │  │OTel Collector│
    │(Storage)│  │ (Buffer) │  │              │
    └─────────┘  └────┬─────┘  └──────────────┘
                      │
                      ▼
                ┌──────────┐
                │FluentBit │
                │(Collector)│
                └──────────┘
```

## 🚀 Components

### 1. **Metrics: Prometheus + Thanos**
- **Prometheus**: Time-series metrics database
- **Thanos**: Long-term storage and global query view
- **Exporters**: node-exporter, kube-state-metrics
- **Scrape Targets**: Kubernetes API, pods, services

### 2. **Logs: FluentBit → Kafka → Loki**
- **Fluent Bit**: Lightweight log collector (DaemonSet)
- **Kafka**: High-throughput buffer for log streams
- **Loki**: Log aggregation optimized for Kubernetes
- **Retention**: 7 days default

### 3. **Traces: OTel Collector → Tempo**
- **OpenTelemetry Collector**: Vendor-agnostic trace collection
- **Tempo**: Distributed tracing backend
- **Protocols**: OTLP, Jaeger, Zipkin
- **Retention**: 7 days default

### 4. **Visualization: Grafana**
- **Dashboards**: Cluster overview, application metrics, logs, traces
- **Datasources**: Prometheus, Loki, Tempo
- **Access**: https://grafana.longops.io.vn
- **Credentials**: admin / Admin@123456

### 5. **Alerting: Alertmanager → Gmail**
- **Alert Rules**: CPU, memory, pod restarts, application errors
- **Notification**: Email via Gmail SMTP
- **Routing**: Critical, warning, info levels

## 📦 Installation

### Prerequisites
```bash
# Helm installed
helm version

# kubectl connected to AKS
kubectl cluster-info

# Namespace
kubectl create namespace monitoring
```

### 1. Deploy Prometheus Stack
```powershell
cd Infrastructure/observability/prometheus
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

Or manually:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml \
  --wait
```

### 2. Deploy Loki
```bash
cd Infrastructure/observability/loki

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki \
  --namespace monitoring \
  --values values.yaml \
  --wait
```

### 3. Deploy Fluent Bit
```bash
cd Infrastructure/observability/fluent-bit

helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

helm install fluent-bit fluent/fluent-bit \
  --namespace monitoring \
  --values values.yaml \
  --wait
```

### 4. Deploy Tempo
```bash
cd Infrastructure/observability/tempo

helm install tempo grafana/tempo \
  --namespace monitoring \
  --values values.yaml \
  --wait
```

### 5. Configure Alerts
```bash
# Update Gmail credentials in alertmanager-gmail-config.yaml
kubectl apply -f prometheus/alertmanager-gmail-config.yaml

# Apply custom alert rules
kubectl apply -f prometheus/alert-rules.yaml
```

## 🔍 Access & Usage

### Grafana Dashboard
```bash
# URL: https://grafana.longops.io.vn
# Username: admin
# Password: Admin@123456

# Port-forward if DNS not configured
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Access: http://localhost:3000
```

### Prometheus UI
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Access: http://localhost:9090
```

### Alertmanager UI
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Access: http://localhost:9093
```

## 📈 Pre-configured Dashboards

Grafana includes:
1. **Kubernetes Cluster Overview** (ID: 7249)
2. **Node Exporter Full** (ID: 1860)
3. **FTM Application Metrics** (Custom)
4. **Loki Logs Explorer**
5. **Tempo Trace Viewer**

## 🔔 Alert Rules

### Critical Alerts
- FTM Backend/Frontend down > 2min
- Node memory > 95%
- PersistentVolume < 10% free

### Warning Alerts
- High error rate (> 5%)
- High CPU usage (> 80%)
- High memory usage (> 90%)
- Pod crash looping

### Notifications
- **Critical**: Immediate email
- **Warning**: Grouped, repeat every 4h
- **Resolved**: Notification sent

## 🛠️ Configuration

### Add Datasource to Grafana
Grafana → Configuration → Data Sources → Add data source

**Loki:**
- URL: `http://loki-gateway.monitoring.svc.cluster.local`
- Access: Server (default)

**Tempo:**
- URL: `http://tempo.monitoring.svc.cluster.local:3100`
- Access: Server (default)

### Gmail Alert Setup
1. Enable 2-Step Verification: https://myaccount.google.com/security
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Update `alertmanager-gmail-config.yaml`:
   ```yaml
   smtp_auth_username: 'your-gmail@gmail.com'
   smtp_auth_password_file: /etc/alertmanager/secrets/gmail-app-password
   ```
4. Apply config:
   ```bash
   kubectl apply -f prometheus/alertmanager-gmail-config.yaml
   ```

### Custom Metrics in Application

**Backend (.NET):**
```csharp
// Add Prometheus metrics
app.UseMetricServer();
app.UseHttpMetrics();
```

**Frontend (React):**
```javascript
// Add OpenTelemetry instrumentation
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
```

## 📊 Monitoring Resources

### Check Status
```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get pvc -n monitoring
```

### View Metrics
```bash
# Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# ServiceMonitors
kubectl get servicemonitor -n monitoring
```

### Logs
```bash
# Fluent Bit logs
kubectl logs -n monitoring -l app.kubernetes.io/name=fluent-bit --tail=100

# Loki logs
kubectl logs -n monitoring -l app.kubernetes.io/name=loki --tail=100
```

## 🧹 Cleanup
```bash
# Remove all observability components
helm uninstall prometheus -n monitoring
helm uninstall loki -n monitoring
helm uninstall fluent-bit -n monitoring
helm uninstall tempo -n monitoring

# Delete PVCs
kubectl delete pvc -n monitoring --all

# Delete namespace
kubectl delete namespace monitoring
```

## 📝 Troubleshooting

### Prometheus targets not found
```bash
# Check ServiceMonitors
kubectl get servicemonitor -n monitoring

# Check service labels match
kubectl get svc -n ftm-dev --show-labels
```

### Loki not receiving logs
```bash
# Check Fluent Bit status
kubectl get pods -n monitoring -l app.kubernetes.io/name=fluent-bit

# Check Fluent Bit logs
kubectl logs -n monitoring -l app.kubernetes.io/name=fluent-bit --tail=50

# Test Loki query
curl http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/labels
```

### Alerts not sending
```bash
# Check Alertmanager config
kubectl get secret -n monitoring alertmanager-prometheus-alertmanager -o yaml

# Check Alertmanager logs
kubectl logs -n monitoring alertmanager-prometheus-alertmanager-0 -c alertmanager

# Test alert
kubectl exec -n monitoring alertmanager-prometheus-alertmanager-0 -c alertmanager -- \
  amtool alert add test_alert
```

## 🔗 Useful Links

- **Prometheus**: https://prometheus.io/docs
- **Grafana**: https://grafana.com/docs
- **Loki**: https://grafana.com/docs/loki/latest
- **Tempo**: https://grafana.com/docs/tempo/latest
- **Fluent Bit**: https://docs.fluentbit.io
- **Thanos**: https://thanos.io/tip/thanos/quick-tutorial.md

## 📌 Next Steps

1. ✅ Configure DNS for grafana.longops.io.vn
2. ⏳ Setup Thanos for long-term storage
3. ⏳ Configure Kafka for log buffering
4. ⏳ Instrument application code with metrics/traces
5. ⏳ Create custom FTM application dashboard
6. ⏳ Test alert notifications
