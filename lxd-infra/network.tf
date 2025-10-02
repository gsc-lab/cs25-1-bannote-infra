# 동일한 서버를 사용하는 경우 두 개의 네트워크를 하나의 ip 에 할당할 수 없기 때문에 별도의 network-forward-infra에서 관리

resource "lxd_network" "env_net" {
  name = "lxdbr-${var.environment}"

  config = {
    # main: 10.246.200.0/24, dev: 10.246.201.0/24로 분리
    "ipv4.address" = var.environment == "main" ? "10.246.200.1/24" : "10.246.201.1/24"
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
  }
}

# LXD Network Forward 설정
# 외부 IP에서 LXD 인스턴스로 포트 포워딩

# 모든 포트 매핑을 평탄화
locals {
  all_port_mappings = flatten([
    [
      for cluster_key, cluster in local.target_clusters : [
        for port in cluster.ports : {
          description    = "${cluster.name}-${port.name}"
          protocol       = "tcp"
          listen_port    = tostring(port.listen_port)
          target_address = cluster_key
          target_port    = tostring(port.connect_port)
        }
      ]
    ],
    [
      {
        description    = "${var.environment}-http-prod"
        protocol       = "tcp"
        listen_port    = "80"
        target_address = "bannote-${var.environment}-prod"
        target_port    = "30080"
      },
      {
        description    = "${var.environment}-https-prod"
        protocol       = "tcp"
        listen_port    = "443"
        target_address = "bannote-${var.environment}-prod"
        target_port    = "30443"
      }
    ]
  ])
}

# 하나의 network forward로 모든 포트 관리
resource "lxd_network_forward" "main" {
  network        = lxd_network.env_net.name
  listen_address = var.lxd_host_ip

  # ports는 리스트 속성 (동적 블록 아님)
  ports = [
    for mapping in local.all_port_mappings : {
      description    = mapping.description
      protocol       = mapping.protocol
      listen_port    = mapping.listen_port
      target_address = local.public_ipv4_addresses[mapping.target_address]
      target_port    = mapping.target_port
    }
  ]

  depends_on = [lxd_instance.cluster_vms]
}