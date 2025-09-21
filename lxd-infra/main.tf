# 깃허브 액션스에서 받은 변수에 따라 생성할 클러스터 목록을 필터링합니다.
locals {
  target_clusters = {
    for key, cluster in var.clusters : key => cluster
    if startswith(key, "bannote-${var.environment}-")
  }
}

# 필터링된 클러스터 목록만 생성
resource "lxd_instance" "cluster_vms" {
  for_each = local.target_clusters
  name     = each.value.name
  image    = each.value.image
  type     = "virtual-machine"

  limits = {
    cpu = each.value.cpu_limit
    memory = each.value.memory_limit
  }
}

# VM의 IP 주소를 출력
output "vm_ips" {
  value = { for name, instance in lxd_instance.cluster_vms : name => instance.network_interface[0].ipv4_address }
}