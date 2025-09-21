output "instance_ips" {
  description = "The IP addresses of the created LXD instances"
  value = {
    for k, v in lxd_instance.cluster_vms : k => v.ipv4_address
  }
  sensitive = true
}
