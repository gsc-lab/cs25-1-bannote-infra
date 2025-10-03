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
