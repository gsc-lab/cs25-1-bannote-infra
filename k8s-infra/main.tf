terraform {
  backend "local" {
    path = "/home/bannote/.terraform-state/k8s-state.tfstate"
  }
}

locals {
  runner_name_parts = split("-", var.runner_name)
  # runner의 이름에서 "-"로 나누었을 때의 가장 마지막 값을 가져옴 (ex: prod, stg, dev)
  environment       = element(local.runner_name_parts, length(local.runner_name_parts) - 1)
}

# ArgoCD secrets 복호화 (Terraform helm provider는 helm-secrets 플러그인 미지원)
data "external" "argocd_secrets" {
  program = ["helm", "secrets", "decrypt", "--terraform", "${path.module}/../helm/infrastructure/values/argocd/shared/secrets.sops.yaml"]
}

resource "helm_release" "argocd" {
  create_namespace = true  # Helm이 자동으로 namespace 생성
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  values = [
    file("${path.module}/../helm/infrastructure/values/argocd/shared/values.yaml"),
    base64decode(data.external.argocd_secrets.result.content_base64)
  ]
}
