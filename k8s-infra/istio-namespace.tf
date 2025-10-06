# envoy를 사이드카로 배포하여 모니터링 하기 위해서 라벨이 붙은 네임스페이스 사전 생성

# Istio Ingress Namespace - 사전 생성 with istio-injection label
resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# MinIO Namespace - minio 스토리지 전용 네임스페이스
resource "kubernetes_namespace" "minio" {
  metadata {
    name = "minio"
    labels = {
      "name" = "minio"
      "istio-injection" = "enabled"
    }
  }
}
