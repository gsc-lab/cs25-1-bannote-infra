terraform {
  cloud {
    organization = "bannote"

    # 동적 workspace 선택을 위해 tags 사용
    workspaces {
      tags = ["bannote-server"]
    }
  }
}

# 깃허브 액션스에서 받은 변수에 따라 생성할 클러스터 목록을 필터링
locals {
  # Enrich cluster data with port forwarding rules based on the hybrid model
  enriched_clusters = {
    for key, cluster in var.clusters : key => merge(
      cluster,
      {
        ports = [
          for i, p in var.common_ports : {
            name         = p.name
            # Use conditional logic to choose the mapping strategy
            listen_port  = p.use_direct_mapping ? (cluster.base_port + p.port) : (cluster.base_port + i)
            connect_port = p.port
          }
        ]
      }
    )
  }

  # Filter for the target environment as before
  target_clusters = {
    for key, cluster in local.enriched_clusters : key => cluster
    if startswith(key, "bannote-${var.environment}-")
  }
}

# LXD 인스턴스 생성 (프록시 디바이스 포함)
resource "lxd_instance" "cluster_vms" {
  for_each = local.target_clusters
  name     = each.value.name
  image    = each.value.image
  type     = "virtual-machine"

  limits = {
    cpu    = each.value.cpu_limit
    memory = each.value.memory_limit
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.env_net.name
      name    = "eth0"
    }
  }

  config = {
    "cloud-init.user-data" = <<-EOF
#cloud-config
users:
  - name: bannote
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${var.ssh_public_key}
EOF
  }
}
