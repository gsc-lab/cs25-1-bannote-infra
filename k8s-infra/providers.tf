terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.11.0"
    }
  }
}

provider "kubernetes" {
  config_path = "/home/bannote/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "/home/bannote/.kube/config"
  }
}

data "kubernetes_secret" "argocd_admin" {
  count = fileexists("/home/bannote/.kube/config") ? 1 : 0

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }

  depends_on = [helm_release.argocd]
}

provider "argocd" {
  server_addr = "127.0.0.1:30002"
  username    = "admin"
  password    = try(data.kubernetes_secret.argocd_admin[0].data["password"], "")
  insecure    = true
}
