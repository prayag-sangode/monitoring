# Redis Cluster Monitoring with Prometheus and Grafana

This guide will help you set up Prometheus, Grafana, and Redis Cluster with metrics monitoring using Helm on Kubernetes.

## Prerequisites

- Kubernetes cluster running (This is tested on minikube)
- Helm installed
- kubectl configured to access the Kubernetes cluster

## 1. Install Prometheus and Grafana

First, add the Prometheus community Helm repository and install `kube-prometheus-stack`:

```bash
# Add Prometheus community Helm chart repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install or upgrade kube-prometheus-stack in the monitoring namespace
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version 68.3.2 -n monitoring --create-namespace

# List installed releases in the monitoring namespace
helm -n monitoring ls
```

### 2. Access Prometheus and Grafana Dashboards

To access Prometheus and Grafana locally, use the following port-forwarding commands:

```bash
# Port-forward to access Prometheus dashboard (http://localhost:9090)
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090 --address 0.0.0.0

# Port-forward to access Grafana dashboard (http://localhost:3000)
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80 --address 0.0.0.0
```

### 3. Install Redis Cluster with Monitoring Enabled

Create a `redis-cluster-values.yaml` file with the following content to configure Redis and enable monitoring:

```yaml
master:
  persistence:
    enabled: false

replica:
  persistence:
    enabled: false

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    port: http-metrics
    namespace: "monitoring"  # Namespace where Prometheus is running
    interval: 30s
    scrapeTimeout: "10s"
    relabelings: []
    metricRelabelings: []
    honorLabels: true
    additionalLabels:
      release: kube-prometheus-stack
    podTargetLabels: []
    sampleLimit: false
    targetLimit: false
    additionalEndpoints: []
```

Install Redis Cluster using the values defined in `redis-cluster-values.yaml`:

```bash
# Add Bitnami Helm chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install Redis Cluster with the custom values
helm upgrade --install redis-cluster bitnami/redis --version 20.6.3 -f redis-cluster-values.yaml -n redis-cluster --create-namespace
```

### 4. Verify Redis Cluster Installation

Once the Redis Cluster is installed, you can verify its deployment in the `redis-cluster` namespace:

```bash
kubectl get pods -n redis-cluster
```

### 5. Create a ServiceMonitor for Redis Metrics (Not require, if using above values file)

For Prometheus to scrape metrics from Redis, create a `redis-service-monitor.yaml` file:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: redis-cluster-monitor
  namespace: monitoring
  labels:
    release: kube-prometheus-stack  # Matches the Prometheus release label
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: metrics
      app.kubernetes.io/instance: redis-cluster
      app.kubernetes.io/name: redis
  namespaceSelector:
    matchNames:
    - redis-cluster
  endpoints:
  - port: http-metrics
    path: /metrics
    interval: 30s
    scheme: http
```

Apply the `redis-service-monitor.yaml` file to create the `ServiceMonitor` resource:

```bash
kubectl apply -f redis-service-monitor.yaml
```

This will enable Prometheus to start scraping metrics from Redis.

### 6. Use Redis Grafana Dashboard

Import the Redis Grafana dashboard from the Grafana website:

- **Dashboard ID**: [11835](https://grafana.com/grafana/dashboards/11835-redis-dashboard-for-prometheus-redis-exporter-helm-stable-redis-ha/)
- This dashboard is specifically designed for monitoring Redis with Prometheus and Redis Exporter.

#### Steps to Import the Dashboard:

1. Open Grafana at `http://localhost:3000`.
2. Log in using the default credentials:
   - **Username**: `admin`
   - **Password**: `prom-operator`
3. Go to **Create** -> **Import**.
4. Enter the **Dashboard ID** `11835` and click **Load**.
5. Select the Prometheus data source (usually the default).
6. Click **Import** to add the dashboard.

### 7. Access Redis Metrics in Grafana

Once the dashboard is imported, you can view Redis metrics in Grafana by selecting the relevant panels to monitor Redis performance and health.
