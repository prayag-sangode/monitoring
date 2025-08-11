# Testing Prometheus Alerts in Kubernetes (Single Deployment)

This guide demonstrates how to test **Pod Down**, **High CPU**, **High Memory**, and **Cluster-Wide High CPU Utilization** alerts using a **single Kubernetes deployment**.
We’ll use an `nginx` pod with **low CPU & memory limits**, so it’s easy to trigger resource-based alerts.

---

## Deploy Nginx with CPU & Memory Limits

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-stress
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-stress
  template:
    metadata:
      labels:
        app: nginx-stress
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
EOF
```

Verify deployment:

```bash
kubectl get pods -n default -l app=nginx-stress
```

---

## 2️⃣ Test **Pod Down** Alert

### Option A – Scale to 0

```bash
kubectl scale deployment nginx-stress --replicas=0 -n default
```

### Option B – Break the container image

```bash
kubectl set image deployment/nginx-stress nginx=nginx:nonexistent-tag -n default
```

The pod should move into `ImagePullBackOff` or `ErrImagePull` state.

**Expected Alerts**:

* `PodNotRunningInDefault`
* `ContainerCreatingFor5Minutes`

---

## 3️⃣ Test **High CPU Usage** Alert

```bash
kubectl exec -it deployment.apps/nginx-stress -- /bin/bash
apt update && apt -y install stress-ng
stress-ng --cpu 1 --cpu-load 100 --timeout 600s
```

**Expected Alerts**:

* `HighCPUUsageTopKPods`
* `CPUThrottlingRatioHigh`
* `PodCPUThrottlingDetected`

---

## 4️⃣ Test **High Memory Usage** Alert

```bash
kubectl exec -it deployment.apps/nginx-stress -- /bin/bash
apt update && apt -y install stress-ng
stress-ng --vm 1 --vm-bytes 240M --vm-hang 0 --timeout 600s
```

**Expected Alerts**:

* `HighMemoryUsage`
* `MemoryUtilizationTooHigh`

---

## 5️⃣ Test **Cluster-Wide High CPU Utilization** Alert

To simulate high CPU usage across the cluster:

```bash
# Scale up replicas to run CPU stress on multiple pods
kubectl scale deployment nginx-stress --replicas=6 -n default

# Run stress-ng on each pod (open separate shells or run in background)
for pod in $(kubectl get pods -n default -l app=nginx-stress -o name); do
  kubectl exec -n default $pod -- \
    sh -c "apt update && apt -y install stress-ng && stress-ng --cpu 1 --cpu-load 100 --timeout 600s" &
done
```

**Expected Alerts**:

* `ClusterHighCPUUtilization`

---

## 6️⃣ Cleanup

```bash
kubectl delete deployment nginx-stress -n default
```

---

## ⏱ Notes

* The `for:` value in alert rules means alerts will **only fire after being in the warning state for that duration** (e.g., 2–5 minutes).
* Check alerts in:

  * **Prometheus → Alerts tab**
  * **Alertmanager UI**
* Ensure:

  * `kube-state-metrics` and `cadvisor` are running and scraped.
  * Namespace filters in your alert rules include `default`.

