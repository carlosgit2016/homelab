output "phoenix_id" {
  description = "Phoenix VM ID"
  value       = module.phoenix.vm_id
}

output "phoenix_ip" {
  description = "Phoenix control plane IP address"
  value       = module.phoenix.ip_address
}

output "yamato_id" {
  description = "Yamato VM ID"
  value       = module.yamato.vm_id
}

output "yamato_ip" {
  description = "Yamato worker IP address"
  value       = module.yamato.ip_address
}

output "defcom_id" {
  description = "Defcom VM ID"
  value       = module.defcom.vm_id
}

output "defcom_ip" {
  description = "Defcom worker IP address"
  value       = module.defcom.ip_address
}
