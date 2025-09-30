# LXD Network Forward 설정
# 외부 IP에서 LXD 인스턴스로 포트 포워딩

# 모든 포트 매핑을 평탄화
locals {
  all_port_mappings = flatten([
    for cluster_key, cluster in local.target_clusters : [
      for port in cluster.ports : {
        description    = "${cluster.name}-${port.name}"
        protocol       = "tcp"
        listen_port    = tostring(port.listen_port)
        target_address = cluster_key
        target_port    = tostring(port.connect_port)
      }
    ]
  ])
}

# 하나의 network forward로 모든 포트 관리
resource "lxd_network_forward" "main" {
  network        = "lxdbr0"
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