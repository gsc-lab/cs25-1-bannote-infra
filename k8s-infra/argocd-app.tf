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
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/charts/istio-istiod"

      helm {
        release_name = "istiod"
        value_files  = [
          "../../values/istiod/values.yaml",
          "secrets://../../values/istiod/secrets.sops.yaml"
        ]
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
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/charts/istio-gateway"

      helm {
        release_name = "istio-ingressgateway"
        value_files  = [
          "../../values/istio-gateway/values.yaml",
          "secrets://../../values/istio-gateway/secrets.sops.yaml"
        ]
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
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/charts/prometheus"

      helm {
        release_name = "prometheus"
        value_files  = [
          "../../values/prometheus/values.yaml",
          "secrets://../../values/prometheus/secrets.sops.yaml"
        ]
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
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/charts/grafana"

      helm {
        release_name = "grafana"
        value_files  = [
          "../../values/grafana/values.yaml",
          "secrets://../../values/grafana/secrets.sops.yaml"
        ]
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
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/charts/kiali"

      helm {
        release_name = "kiali"
        value_files  = [
          "../../values/kiali/values.yaml",
          "secrets://../../values/kiali/secrets.sops.yaml"
        ]
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
    argocd_project.infra,
    argocd_repository.infra_repo
  ]
}
