# TODO: 지속적인 CD 작업을 위해 CI 작업 시 1회성으로 가져오는 파일이 아닌, 깃허브 리포지토리의 파일을 참조하도록 변경

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

        values = file("${path.module}/../helm/values/istiod/shared/values.yaml")
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

        values = file("${path.module}/../helm/values/prometheus/shared/values.yaml")
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

        values = file("${path.module}/../helm/values/grafana/shared/values.yaml")
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

        values = file("${path.module}/../helm/values/kiali/shared/values.yaml")
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
