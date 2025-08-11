# Kubernetes Monitoring Stack on GKE (Prometheus + Grafana + Node Exporter)

This guide walks you through deploying a **Prometheus**, **Grafana**, and **Node Exporter** monitoring stack on a **Google Kubernetes Engine (GKE)** cluster.
While this README is written for GKE, the steps work on **any Kubernetes cluster** with `kubectl` and `helm` installed.


##  Create GKE Cluster

```bash
# Set the default compute zone
gcloud config set compute/zone southamerica-east1-a

# Create a GKE cluster with 2 nodes
gcloud container clusters create my-cluster \
  --zone=southamerica-east1-a \
  --num-nodes=2 \
  --project=fiery-plate-461110-v0

# Verify cluster
gcloud container clusters list --zone=southamerica-east1-a

# Check Kubernetes nodes
kubectl get nodes -o wide
```

---

##  Clone Repository

```bash
git clone https://github.com/prayag-sangode/monitoring
cd monitoring/helm
```

---

##  Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

---

##  Add Helm Repositories

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

---

## Deploy Monitoring Components

### **Prometheus**

```bash
helm upgrade --install prometheus prometheus-community/prometheus \
  -n monitoring -f prometheus/prometheus-values.yaml
```

### **Grafana**

```bash
helm upgrade --install grafana grafana/grafana \
  -n monitoring -f grafana/grafana-values.yaml
```

### **Node Exporter**

```bash
helm upgrade --install node-exporter prometheus-community/prometheus-node-exporter \
  -n monitoring -f node-exporter/node-exporter-values.yaml
```

---

##  Verify Deployments

```bash
# List helm repos
helm repo ls

# List helm releases in the monitoring namespace
helm -n monitoring ls

# Get all resources in monitoring namespace
kubectl -n monitoring get all
```

---

##  Access Grafana Password

```bash
kubectl get secret --namespace monitoring grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

---

##  Access Services

If your Helm values files are configured for LoadBalancer services, you can access the tools via the assigned external IPs:

| Service      | Default Port | Access                |
| ------------ | ------------ | --------------------- |
| Prometheus   | 80           | `http://<LB_IP>:80`   |
| AlertManager | 9093         | `http://<LB_IP>:9093` |
| Grafana      | 80           | `http://<LB_IP>:80`   |

To check the external IPs:

```bash
kubectl -n monitoring get svc
```

---

## Cleanup

```bash
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
helm uninstall node-exporter -n monitoring
kubectl delete namespace monitoring
gcloud container clusters delete my-cluster --zone=southamerica-east1-a
```

