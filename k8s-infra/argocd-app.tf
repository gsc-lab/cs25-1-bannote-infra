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
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/istio-base"

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

    ignore_difference{
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "istiod-default-validator"
      json_pointers = [
        "/webhooks/0/failurePolicy",
        "/webhooks/0/clientConfig/caBundle"
      ]
    }
  }

  depends_on = [
    argocd_project.infra, 
    argocd_repository.infra_repo
  ]
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
      path            = "helm/infrastructure/istio-istiod"

      helm {
        release_name = "istiod"
        value_files  = [
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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

    ignore_difference {
      group = "admissionregistration.k8s.io"
      kind  = "MutatingWebhookConfiguration"
      name  = "istio-sidecar-injector"
      json_pointers = [
        "/webhooks"
      ]
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "istio-validator-istio-system"
      json_pointers = [
        "/webhooks/0/failurePolicy",
        "/webhooks/0/clientConfig/caBundle"
      ]
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
      path            = "helm/infrastructure/istio-gateway"

      helm {
        release_name = "istio-ingressgateway"
        value_files  = [
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
      path            = "helm/infrastructure/prometheus"

      helm {
        release_name = "prometheus"
        value_files  = [
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
      path            = "helm/infrastructure/grafana"

      helm {
        release_name = "grafana"
        value_files  = [
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
      path            = "helm/infrastructure/kiali"

      helm {
        release_name = "kiali"
        value_files  = [
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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

# ======================
# Storage
# ======================

# MinIO (Object Storage)
resource "argocd_application" "minio" {
  metadata {
    name      = "minio"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "minio"
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/minio"

      helm {
        release_name = "minio"
        value_files  = [
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
    kubernetes_namespace.minio,
    argocd_project.infra,
    argocd_repository.infra_repo
  ]
}

resource "argocd_application" "mysql-user-service" {
  metadata {
    name      = "mysql-user-service"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "mysql"
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/mysql-user-service"

      helm {
        release_name = "mysql-user-service"
        value_files  = [
          "values.yaml",
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
    kubernetes_namespace.mysql,
    argocd_project.infra,
    argocd_repository.infra_repo
  ]
}

resource "argocd_application" "mysql-schedule-service" {
  metadata {
    name      = "mysql-schedule-service"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "mysql"
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/mysql-schedule-service"

      helm {
        release_name = "mysql-schedule-service"
        value_files  = [
          "values.yaml",
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
    kubernetes_namespace.mysql,
    argocd_project.infra,
    argocd_repository.infra_repo
  ]
}

resource "argocd_application" "mysql-studyroom-service" {
  metadata {
    name      = "mysql-studyroom-service"
    namespace = "argocd"
  }

  spec {
    project = "infra"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "mysql"
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/infrastructure/mysql-studyroom-service"

      helm {
        release_name = "mysql-studyroom-service"
        value_files  = [
          "values.yaml",
          "values/shared/values.yaml",
          "secrets://values/shared/secrets.sops.yaml"
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
    kubernetes_namespace.mysql,
    argocd_project.infra,
    argocd_repository.infra_repo
  ]
}

# ======================
# Service Project Applications
# ======================

# API Gateway
resource "argocd_application" "api-gateway" {
  metadata {
    name      = "api-gateway"
    namespace = "argocd"
  }

  spec {
    project = "service"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "api-gateway"
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/service/api-gateway"

      helm {
        release_name = "api-gateway"
        value_files  = [
          "values/${local.environment}/values.yaml",
          "secrets://values/${local.environment}/secrets.sops.yaml"
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
    argocd_project.service,
    argocd_repository.infra_repo,
    kubernetes_namespace.api-gateway
  ]
}

# Token Service
resource "argocd_application" "token-service" {
  metadata {
    name      = "token-service"
    namespace = "argocd"
  }

  spec {
    project = "service"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "token-service"
    }

    source {
      repo_url        = local.github_repo_url
      target_revision = local.github_revision
      path            = "helm/service/token-service"

      helm {
        release_name = "token-service"
        value_files  = [
          "values/${local.environment}/values.yaml",
          "secrets://values/${local.environment}/secrets.sops.yaml"
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
    argocd_project.service,
    argocd_repository.infra_repo,
    kubernetes_namespace.token-service
  ]
}