# lxd의 외부 연결 ip4 아이피를 추출
locals {
  public_ipv4_addresses = {
    for k, v in lxd_instance.cluster_vms : k => element(
      flatten([
        for iface_data in values(v.interfaces) : [
          for ip in iface_data.ips : ip.address if ip.family == "inet" && ip.scope == "global"
        ]
      ]),
      0
    )
  }
}

# 외부 연결 ip4 출력
output "public_ipv4_addresses" {
  description = "The public IPv4 addresses of the instances, dynamically filtered from all interfaces."
  value       = local.public_ipv4_addresses
}

# 앤서블에서 이용 할 수 있도록, ~/inventory/inventory-{env}에 저장
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    instance_ips = local.public_ipv4_addresses
    env = var.environment
  })
  filename = "${pathexpand("~")}/inventory/inventory-${var.environment}"
  file_permission = "0644"
}

# 저장된 파일 주소 출력
output "inventory_file" {
  description = "Path to the generated Ansible inventory file"
  value = local_file.ansible_inventory.filename
}
