variable "environment" {
  description = "환경을 설정 할 브랜치 (main, dev)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH 공개키"
  type        = string
  sensitive   = true
}

variable "clusters" {
  description = "구축할 LXD 클러스터 설정"
  type = map(object({
    name         = string
    image        = string
    cpu_limit    = string
    memory_limit = string
    disk_size    = string
    base_port    = number
  }))
  default = {
    "bannote-main-prod" = {
      name         = "bannote-main-prod"
      image        = "ubuntu:22.04"
      cpu_limit    = "8"
      memory_limit = "16GB"
      disk_size    = "200GB"
      base_port    = 8000
    }
    "bannote-main-stg" = {
      name         = "bannote-main-stg"
      image        = "ubuntu:22.04"
      cpu_limit    = "4"
      memory_limit = "16GB"
      disk_size    = "50GB"
      base_port    = 8100
    }
    "bannote-main-dev" = {
      name         = "bannote-main-dev"
      image        = "ubuntu:22.04"
      cpu_limit    = "4"
      memory_limit = "16GB"
      disk_size    = "50GB"
      base_port    = 8200
    }
    "bannote-dev-prod" = {
      name         = "bannote-dev-prod"
      image        = "ubuntu:22.04"
      cpu_limit    = "4"
      memory_limit = "16GB"
      disk_size    = "50GB"
      base_port    = 9000
    }
    "bannote-dev-stg" = {
      name         = "bannote-dev-stg"
      image        = "ubuntu:22.04"
      cpu_limit    = "4"
      memory_limit = "16GB"
      disk_size    = "30GB"
      base_port    = 9100
    }
    "bannote-dev-dev" = {
      name         = "bannote-dev-dev"
      image        = "ubuntu:22.04"
      cpu_limit    = "6"
      memory_limit = "16GB"
      disk_size    = "30GB"
      base_port    = 9200
    }
  }
}

variable "common_ports" {
  description = "각 환경 별 외부로 연결 시킬 포트 번호"
  type = list(object({
    name               = string
    port               = number # 컨테이너 내부 포트
    use_direct_mapping = bool
  }))
  default = [
    # TODO: 실제 운영 시에는 Ingress로 변경 필요
    # 순차적 할당 (listen = base_port + index)
    # listen: base_port + 0  (e.g., 8000)
    { name = "ssh",                     port = 22,    use_direct_mapping = false }, // 0
    { name = "http",                    port = 30001, use_direct_mapping = false }, // 1
    { name = "https",                   port = 30002, use_direct_mapping = false }, // 2
    { name = "kiali-dashboard",         port = 30003, use_direct_mapping = false }, // 3
    { name = "argocd-http-dashboard",   port = 30004, use_direct_mapping = false }, // 4
    { name = "argocd-https-dashboard",  port = 30005, use_direct_mapping = false }, // 5
    { name = "prometheus-dashboard",    port = 30006, use_direct_mapping = false }, // 6
    { name = "grafana-dashboard",       port = 30007, use_direct_mapping = false }, // 7
    { name = "minio-api",               port = 30008, use_direct_mapping = false }, // 8
    { name = "minio-dashboard",         port = 30009, use_direct_mapping = false }, // 9
    { name = "kafka-ui",                port = 30010, use_direct_mapping = false }  // 10

    # 지정 번호 할당 (listen = base_port + port)
    # listen: base_port + 80   (e.g., 8080)
    # { name = "http",              port = 80,   use_direct_mapping = true },
    # listen: base_port + 443  (e.g., 8443)
    # { name = "https",             port = 443,  use_direct_mapping = true },
    # listen: base_port + 22   (e.g., 8022)
    # { name = "ssh",               port = 22,   use_direct_mapping = true }
  ]
}

variable "lxd_host_ip" {
  description = "프록시 장치가 리슨할 LXD 호스트의 IP 주소"
  type        = string
}
