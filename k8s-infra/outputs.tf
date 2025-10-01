# ArgoCD 접속 정보 출력
output "argocd_namespace" {
  description = "ArgoCD가 설치된 네임스페이스"
  value       = helm_release.argocd.namespace
}

output "argocd_server_service" {
  description = "ArgoCD 서버 서비스 이름"
  value       = "${helm_release.argocd.name}-server"
}

output "argocd_access_info" {
  description = "ArgoCD 접속 방법"
  value = <<-EOT
    ArgoCD 설치 완료!

    1. ArgoCD 서버 포트 포워딩:
       kubectl port-forward svc/argocd-server -n argocd 8080:443

    2. 웹 브라우저에서 접속:
       http://localhost:8080

    3. 초기 admin 비밀번호 확인:
       kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

    4. 로그인:
       Username: admin
       Password: (위 명령어로 조회한 비밀번호)
  EOT
}

output "argocd_cli_login" {
  description = "ArgoCD CLI 로그인 명령어"
  value       = "argocd login localhost:8080 --insecure --username admin"
}