# ArgoCD Projects 정의

# Infra Project: 인프라 컴포넌트 (Istio, Monitoring 등)
resource "argocd_project" "infra" {
  metadata {
    name      = "infra"
    namespace = "argocd"
  }

  spec {
    description  = "Infrastructure components (Istio, Prometheus, etc.)"
    source_repos = ["*"]  # 모든 Git 저장소 허용

    # 배포 가능한 네임스페이스
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-system"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "istio-ingress"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "monitoring"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "kube-system"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "minio"
    }

    # 클러스터 리소스 생성 권한
    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }

    # Namespace 리소스 권한
    namespace_resource_whitelist {
      group = "*"
      kind  = "*"
    }

    # Orphaned resources 정책
    orphaned_resources {
      warn = true
    }
  }

  depends_on = [ helm_release.argocd ]
}
