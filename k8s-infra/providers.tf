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

data "kubernetes_secret" "argocd_initial_admin_secret" {
    metadata {
      name      = "argocd-initial-admin-secret"
      namespace = "argocd"
    }

    depends_on = [helm_release.argocd]
}

provider "argocd" {
    server_addr = "argocd-server.argocd.svc.cluster.local:443"
    username    = "admin"
    password    = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
    insecure    = true

    kubernetes = {
        config_path = "/home/bannote/.kube/config"
    }
}
