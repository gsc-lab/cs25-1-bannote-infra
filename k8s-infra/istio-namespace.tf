# envoy를 사이드카로 배포하여 모니터링 하기 위해서 라벨이 붙은 네임스페이스 사전 생성

# Istio Ingress Namespace
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
      "istio-injection" = "disabled"
    }
  }
}

# MySql Namespace - MySql 전용 네임스페이스
resource "kubernetes_namespace" "mysql" {
  metadata {
    name = "mysql"
    labels = {
      "name" = "mysql"
      "istio-injection" = "disabled"
    }
  }
}

# API Gateway - API Gateway 서비스 전용 네임스페이스
resource "kubernetes_namespace" "api-gateway" {
  metadata {
    name = "api-gateway"
    labels = {
      "name" = "api-gateway"
      "istio-injection" = "enabled"
    }
  }
}

# Token Service - Token Service 서비스 전용 네임스페이스
resource "kubernetes_namespace" "token-service" {
  metadata {
    name = "token-service"
    labels = {
      "name" = "token-service"
      "istio-injection" = "enabled"
    }
  }
}

# User Service - User Service 서비스 전용 네임스페이스
resource "kubernetes_namespace" "user-service" {
  metadata {
    name = "user-service"
    labels = {
      "name" = "user-service"
      "istio-injection" = "enabled"
    }
  }
}

# Schedule Service - Schedule Service 서비스 전용 네임스페이스
resource "kubernetes_namespace" "schedule-service" {
  metadata {
    name = "schedule-service"
    labels = {
      "name" = "schedule-service"
      "istio-injection" = "enabled"
    }
  }
}