variable "runner_name" {
  description = "현재 실행중인 러너의 이름"
  type        = string
}

variable "github_pat_token" {
  description = "value"
  type = string
  sensitive = true
}

variable "github_branch" {
  description = "GitHub branch for ArgoCD values (main or dev)"
  type        = string
  default     = "dev"
}

# TODO: 프로바이더는 secrets 복호화 작업 이전에 초기화 되므로, 실제 이용시에는 외부에서 별도 주입 필요
variable "argocd_admin_password" {
  description = "ArgoCD admin password (plaintext for provider login)"
  type        = string
  default     = "test"
  sensitive   = true
}