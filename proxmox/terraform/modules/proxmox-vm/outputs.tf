output "vm_id" {
  description = "The VM ID"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "The VM name"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "ip_address" {
  description = "The static IP address"
  value       = split("/", var.static_ip)[0]
}

output "network_config_id" {
  description = "The network configuration resource ID for dependency chaining"
  value       = null_resource.network_config.id
}
