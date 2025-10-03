terraform {
  backend "local" {
    path = "/home/bannote/.terraform-state/k8s-state.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }
}

locals {
  runner_name_parts = split("-", var.runner_name)
  # runner의 이름에서 "-"로 나누었을 때의 가장 마지막 값을 가져옴 (ex: prod, stg, dev)
  environment       = element(local.runner_name_parts, length(local.runner_name_parts) - 1)
}

# K3s kubeconfig 경로 (k3s가 자동으로 생성)
provider "kubernetes" {
  config_path = "/home/bannote/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "/home/bannote/.kube/config"
  }
}

resource "helm_release" "argocd" {
  create_namespace = true  # Helm이 자동으로 namespace 생성
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  values = [
    file("${path.module}/../helm/values/argocd/${local.environment}/values.yaml")
  ]
}
