Here is the `README.md` you requested for setting up Prometheus, Grafana, Alertmanager, and testing alerts:

```markdown
# Prometheus and Grafana Setup for Monitoring with Alerts

This guide will help you set up Prometheus, Grafana, and Alertmanager using Helm, configure email alerts, and test pod restarts with `kubectl` and `stress-ng`.

## Step 1: Add Helm Repositories

Add the Prometheus community Helm repository and update it:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Step 2: Install Prometheus Stack

Install the Prometheus stack (including Prometheus, Grafana, and Alertmanager) with a custom `values` file (`prometheus-stack-values.yml`):

```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f prometheus-stack-values.yml --create-namespace
```

## Step 3: Port Forward to Access Prometheus, Grafana, and Alertmanager

Run these commands to port-forward Prometheus, Grafana, and Alertmanager for local access:

- **Prometheus** (accessible at `http://localhost:9090`):

  ```bash
  kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring --address 0.0.0.0
  ```

- **Grafana** (accessible at `http://localhost:8080`):

  ```bash
  kubectl port-forward service/monitoring-grafana -n monitoring 8080:80 --address 0.0.0.0
  ```

  *Grafana login password is `prom-operator`.*

- **Alertmanager** (accessible at `http://localhost:9093`):

  ```bash
  kubectl port-forward service/alertmanager-operated -n monitoring 9093:9093 --address 0.0.0.0
  ```

## Step 4: Configure SMTP Settings for Alertmanager

1. Add your SMTP settings in `alertmanagerconfig.yml` to enable email alerts.

2. Apply the email secrets with the base64 encoded Gmail app password:

   ```bash
   kubectl apply -f email-secrets.yml
   ```

3. Apply the Alertmanager configuration:

   ```bash
   kubectl apply -f alertmangerconfig.yml
   ```

4. Apply custom alert rules:

   ```bash
   kubectl apply -f alerts.yml
   ```

5. Apply the ServiceMonitor configuration:

   ```bash
   kubectl apply -f serviceMonitor.yml
   ```

## Step 5: Create and Test Pods

### Test Pod (Using `stress-ng` to generate CPU load)

1. Create a pod that will run indefinitely:

   ```bash
   kubectl run test-pod --image=ubuntu:latest --restart=Never -- sleep infinity
   ```

2. Enter the pod and run `stress-ng` to generate CPU load:

   ```bash
   kubectl exec -it test-pod -- bash
   stress-ng --cpu 4 --timeout 3000s
   ```

### Test Deployment (Using `sleep infinity` to keep pod alive)

1. Create a deployment that will run a pod with `sleep infinity`:

   ```bash
   kubectl create deployment test-deployment --image=ubuntu:latest -- /bin/bash -c "sleep infinity"
   ```

### Restart the Deployment

To restart the deployment and simulate pod restarts (to trigger the `PodRestart` alert):

```bash
kubectl rollout restart deployment/test-deployment
```

## Step 6: Cleanup

Once testing is complete, you can clean up the resources:

- Delete the test deployment:

  ```bash
  kubectl delete deployment test-deployment
  ```

- Delete the test pod:

  ```bash
  kubectl delete pod test-pod
  ```

---

### Additional Notes

- The Grafana dashboard should be configured to display the metrics from Prometheus.
- Alerts in Alertmanager will send notifications based on the conditions specified in `alerts.yml`.
- Ensure your `alertmanagerconfig.yml` includes the correct SMTP configuration for sending emails.
```

This `README.md` provides clear instructions to set up the monitoring stack, configure email alerts, and test with Kubernetes pods. Let me know if you need any further modifications!
