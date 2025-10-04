# 프라이빗 리포지토리 접근을 위한 설정 (HTTPS + Token)
resource "argocd_repository" "infra_repo" {
  repo = "https://github.com/gsc-lab/cs25-1-bannote-infra.git"
  type = "git"
  name = "bannote-infra"

  username = "git"
  password = var.github_pat_token
}
