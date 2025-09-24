output "instance_ips" {
  description = "The IP addresses of the created LXD instances"
  value = {
    for k, v in lxd_instance.cluster_vms : k => one([
      for ip in v.network[0].addresses : ip.address if ip.family == "inet6" and ip.scope == "global"
    ])
  }
  sensitive = true
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    instance_ips = { for k, v in lxd_instance.cluster_vms : k => one([
      for ip in v.network[0].addresses : ip.address if ip.family == "inet6" and ip.scope == "global"
    ]) }
    env = var.environment
  })
  filename = "${pathexpand("~")}/inventory/inventory-${var.environment}"
  file_permission = "0644"
}

output "inventory_file" {
  description = "Path to the generated Ansible inventory file"
  value = local_file.ansible_inventory.filename
}
