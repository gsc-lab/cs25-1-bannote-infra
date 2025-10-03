# ======================
# Infra Project Applications
# ======================

# Istio Base (CRDs)
resource "argocd_application" "istio_base" {
  metadata {
    name      = "istio-base"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-system"
    }

    source {
      repo_url        = "https://istio-release.storage.googleapis.com/charts"
      chart           = "base"
      target_revision = "1.27.1"

      helm {
        release_name = "istio-base"
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = ["CreateNamespace=true"]
    }
  }

  depends_on = [argocd_project.infra]
}

# Istio Istiod (Control Plane)
resource "argocd_application" "istio_istiod" {
  metadata {
    name      = "istio-istiod"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-system"
    }

    source {
      repo_url        = "https://istio-release.storage.googleapis.com/charts"
      chart           = "istiod"
      target_revision = "1.27.1"

      helm {
        release_name = "istiod"

        values = <<-EOT
          pilot:
            podLabels:
              app: istiod
              version: v1
        EOT
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = []
    }
  }

  depends_on = [
    argocd_application.istio_base,
    argocd_project.infra
  ]
}

# Istio Gateway (Ingress)
resource "argocd_application" "istio_gateway" {
  metadata {
    name      = "istio-gateway"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-ingress"
    }

    source {
      repo_url        = "https://istio-release.storage.googleapis.com/charts"
      chart           = "gateway"
      target_revision = "1.27.1"

      helm {
        release_name = "istio-ingressgateway"

        values = file("${path.module}/../helm/values/istio-gateway/shared/values.yaml")
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = []
    }
  }

  depends_on = [
    argocd_application.istio_istiod,
    argocd_project.infra,
    kubernetes_namespace.istio_ingress
  ]
}

# ======================
# Observability
# ======================

# Prometheus (Metrics Collection)
resource "argocd_application" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-system"
    }

    source {
      repo_url        = "https://prometheus-community.github.io/helm-charts"
      chart           = "prometheus"
      target_revision = "25.28.0"

      helm {
        release_name = "prometheus"

        values = <<-EOT
          server:
            service:
              type: ClusterIP
            persistentVolume:
              enabled: true
              size: 8Gi
            podLabels:
              app: prometheus
              version: v1
          alertmanager:
            enabled: false
          prometheus-pushgateway:
            enabled: false
          serverFiles:
            prometheus.yml:
              scrape_configs:
                - job_name: 'kubernetes-pods'
                  kubernetes_sd_configs:
                    - role: pod
                  relabel_configs:
                    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                      action: keep
                      regex: true
                    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
                      action: replace
                      target_label: __metrics_path__
                      regex: (.+)
                    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
                      action: replace
                      regex: ([^:]+)(?::\d+)?;(\d+)
                      replacement: $1:$2
                      target_label: __address__
        EOT
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = []
    }
  }

  depends_on = [
    argocd_application.istio_istiod,
    argocd_project.infra
  ]
}

# Grafana (Visualization)
resource "argocd_application" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-system"
    }

    source {
      repo_url        = "https://grafana.github.io/helm-charts"
      chart           = "grafana"
      target_revision = "8.8.2"

      helm {
        release_name = "grafana"

        values = <<-EOT
          adminPassword: admin
          service:
            type: ClusterIP
          persistence:
            enabled: true
            size: 10Gi
          podLabels:
            app: grafana
            version: v1
          datasources:
            datasources.yaml:
              apiVersion: 1
              datasources:
                - name: Prometheus
                  type: prometheus
                  url: http://prometheus-server
                  access: proxy
                  isDefault: true
        EOT
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = []
    }
  }

  depends_on = [
    argocd_application.prometheus,
    argocd_project.infra
  ]
}

# Kiali (Istio Dashboard)
resource "argocd_application" "kiali" {
  metadata {
    name      = "kiali"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-system"
    }

    source {
      repo_url        = "https://kiali.org/helm-charts"
      chart           = "kiali-server"
      target_revision = "2.3.0"

      helm {
        release_name = "kiali"

        values = <<-EOT
          auth:
            strategy: anonymous
          deployment:
            accessible_namespaces:
              - '**'
            pod_labels:
              app: kiali
              version: v1
          server:
            service_type: NodePort
            node_port: 30000
          external_services:
            istio:
              config_map_name: istio
              istiod_deployment_name: istiod
              istio_sidecar_injector_config_map_name: istio-sidecar-injector
            prometheus:
              url: http://prometheus-server
            grafana:
              url: http://grafana
        EOT
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = []
    }
  }

  depends_on = [
    argocd_application.istio_istiod,
    argocd_application.prometheus,
    argocd_application.grafana,
    argocd_project.infra
  ]
}
