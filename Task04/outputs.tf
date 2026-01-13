output "vpc_id" {
  description = "ID of the created VPC"
  value       = yandex_vpc_network.main.id
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = yandex_vpc_network.main.name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = merge(
    { for k, v in yandex_vpc_subnet.private_subnets : k => v.id },
    var.enable_nat ? { public = yandex_vpc_subnet.public_subnet[0].id } : {}
  )
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.enable_nat ? yandex_vpc_gateway.nat_gateway[0].id : null
}

output "vm_instances" {
  description = "Information about created VM instances"
  value = {
    for k, v in yandex_compute_instance.vms : k => {
      id         = v.id
      name       = v.name
      zone       = v.zone
      fqdn       = v.fqdn
      internal_ip = v.network_interface[0].ip_address
      external_ip = try(v.network_interface[0].nat_ip_address, null)
    }
  }
}

output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value = {
    medical        = yandex_vpc_security_group.medical.id
    fintech        = yandex_vpc_security_group.fintech.id
    ai_services    = yandex_vpc_security_group.ai_services.id
    analytics      = yandex_vpc_security_group.analytics.id
    shared_services = yandex_vpc_security_group.shared_services.id
  }
}

output "ssh_connection_info" {
  description = "SSH connection information for VMs"
  value = {
    for k, v in yandex_compute_instance.vms : k => {
      internal = "ssh ubuntu@${v.network_interface[0].ip_address}"
      external = v.network_interface[0].nat_ip_address != null ? "ssh ubuntu@${v.network_interface[0].nat_ip_address}" : "Use bastion host or VPN"
    }
  }
}
