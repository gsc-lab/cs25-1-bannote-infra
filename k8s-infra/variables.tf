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