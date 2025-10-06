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

provider "argocd" {
  server_addr = "127.0.0.1:30005"
  username    = "admin"
  password    = var.argocd_admin_password
  insecure    = true
}
