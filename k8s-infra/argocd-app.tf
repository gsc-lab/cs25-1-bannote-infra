# ======================
# Infra Project Applications
# ======================

locals {
  github_repo_url = "https://github.com/gsc-lab/cs25-1-bannote-infra.git"
  github_revision = var.github_branch
}

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
        value_files  = [
          "$values/helm/values/istiod/shared/values.yaml",
          "secrets://$values/helm/values/istiod/shared/secrets.sops.yaml"
        ]
      }
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      ref             = "values"
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
    argocd_project.infra,
    argocd_repository.infra_repo
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
        value_files  = [
          "$values/helm/values/istio-gateway/shared/values.yaml",
          "secrets://$values/helm/values/istio-gateway/shared/secrets.sops.yaml"
        ]
      }
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      ref             = "values"
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
    kubernetes_namespace.istio_ingress,
    argocd_repository.infra_repo
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
        value_files  = [
          "$values/helm/values/prometheus/shared/values.yaml",
          "secrets://$values/helm/values/prometheus/shared/secrets.sops.yaml"
        ]
      }
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      ref             = "values"
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
    argocd_repository.infra_repo
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
        value_files  = [
          "$values/helm/values/grafana/shared/values.yaml",
          "secrets://$values/helm/values/grafana/shared/secrets.sops.yaml"
        ]
      }
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      ref             = "values"
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
    argocd_project.infra,
    argocd_repository.infra_repo
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
        value_files  = [
          "$values/helm/values/kiali/shared/values.yaml",
          "secrets://$values/helm/values/kiali/shared/secrets.sops.yaml"
        ]
      }
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      ref             = "values"
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
    argocd_project.infra,
    argocd_repository.infra_repo
  ]
}
