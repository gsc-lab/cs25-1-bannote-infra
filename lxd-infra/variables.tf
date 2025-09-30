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
  type = map(object({
    name         = string
    image        = string
    cpu_limit    = string
    memory_limit = string
    base_port    = number
  }))
  default = {
    "bannote-main-prod" = {
      name         = "bannote-main-prod"
      image        = "ubuntu:22.04"
      cpu_limit    = "4"
      memory_limit = "8GB"
      base_port    = 8000
    }
    "bannote-main-stg" = {
      name         = "bannote-main-stg"
      image        = "ubuntu:22.04"
      cpu_limit    = "2"
      memory_limit = "4GB"
      base_port    = 8100
    }
    "bannote-main-dev" = {
      name         = "bannote-main-dev"
      image        = "ubuntu:22.04"
      cpu_limit    = "2"
      memory_limit = "4GB"
      base_port    = 8200
    }
    "bannote-dev-prod" = {
      name         = "bannote-dev-prod"
      image        = "ubuntu:22.04"
      cpu_limit    = "1"
      memory_limit = "2GB"
      base_port    = 9000
    }
    "bannote-dev-stg" = {
      name         = "bannote-dev-stg"
      image        = "ubuntu:22.04"
      cpu_limit    = "1"
      memory_limit = "2GB"
      base_port    = 9100
    }
    "bannote-dev-dev" = {
      name         = "bannote-dev-dev"
      image        = "ubuntu:22.04"
      cpu_limit    = "1"
      memory_limit = "2GB"
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
    # 순차적 할당 (listen = base_port + index)
    # listen: base_port + 0  (e.g., 8000)
    { name = "traefik-dashboard", port = 8080, use_direct_mapping = false },

    # 지정 번호 할당 (listen = base_port + port)
    # listen: base_port + 80   (e.g., 8080)
    { name = "http",              port = 80,   use_direct_mapping = true },
    # listen: base_port + 443  (e.g., 8443)
    { name = "https",             port = 443,  use_direct_mapping = true },
    # listen: base_port + 22   (e.g., 8022)
    { name = "ssh",               port = 22,   use_direct_mapping = true }
  ]
}

variable "lxd_host_ip" {
  description = "프록시 장치가 리슨할 LXD 호스트의 IP 주소"
  type        = string
}
