provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"  # Adjust this if using a different kubeconfig
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  values = [yamlencode({
    grafana = {
      adminPassword = "StrongPassword123"  # Change this to a secure password
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        }
        hosts = ["grafana.example.com"]
        paths = ["/"]
        tls = [{
          secretName = "grafana-tls-secret"
          hosts      = ["grafana.example.com"]
        }]
      }
      persistence = {
        enabled          = true
        type             = "sts"
        accessModes      = ["ReadWriteOnce"]
        size             = "10Gi"
        storageClassName = "standard"  # Change as per your storage class
        finalizers       = "kubernetes.io/pvc-protection"
      }
    },
    
    alertmanager = {
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = "standard"
              resources = {
                requests = { storage = "5Gi" }
              }
            }
          }
        }
      }
    },
    
    prometheus = {
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        }
        hosts = ["prometheus.example.com"]
        paths = ["/"]
        tls = [{
          secretName = "prometheus-tls-secret"
          hosts      = ["prometheus.example.com"]
        }]
      }
      prometheusSpec = {
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = "standard"
              resources = {
                requests = { storage = "20Gi" }
              }
            }
          }
        }
        additionalScrapeConfigs = yamldecode(<<EOT
          - job_name: blackbox-kubernetes-ingresses
            metrics_path: /probe
            params:
              module: [http_2xx]
            kubernetes_sd_configs:
              - role: ingress
            relabel_configs:
              - source_labels: [__meta_kubernetes_ingress_annotation_blackbox_monitoring_enabled]
                action: keep
                regex: true
              - source_labels:
                  [
                    __meta_kubernetes_ingress_scheme,
                    __address__,
                    __meta_kubernetes_ingress_path,
                  ]
                regex: (.+);(.+);(.+)
                replacement: $${1}://$${2}$${3}
                target_label: __param_target
              - target_label: __address__
                replacement: blackbox-exporter-prometheus-blackbox-exporter.monitoring.svc.cluster.local:9115
              - source_labels: [__param_target]
                target_label: instance
              - action: labelmap
                regex: __meta_kubernetes_ingress_label_(.+)
              - source_labels: [__meta_kubernetes_namespace]
                target_label: kubernetes_namespace
              - source_labels: [__meta_kubernetes_ingress_name]
                target_label: ingress_name
        EOT
        )
      }
    }
  })]
}
