# Istio Ingress Namespace - 사전 생성 with istio-injection label
resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [
    argocd_application.istio_istiod
  ]
}
