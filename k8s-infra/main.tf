terraform {
  backend "local" {
    path = "/home/bannote/.terraform-state/k8s-state.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# K3s kubeconfig 경로 (k3s가 자동으로 생성)
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

# ArgoCD 네임스페이스 생성
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  values = [
    yamlencode({
      server = {
        service = {
          type = "NodePort"
          nodePortHttp = 8081
        }
      }
    })
  ]
}

# traefik 대시보드 연결
resource "kubernetes_service_v1" "traefik_dashboard" {
  metadata {
    name = "traefik-dashboard-service"
    namespace = "default"
  }
  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name" = "traefik"
      "app.kubernetes.io/instance" = "traefik-default"
    }

    port {
      name = "dashboard"
      protocol = "TCP"
      port = 8080
      target_port = 8080
      node_port = 8080
    }
  }
}