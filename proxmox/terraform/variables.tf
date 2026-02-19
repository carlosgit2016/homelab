variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "vm_names" {
  description = "VM names"
  type        = list(string)
  default     = ["phoenix", "yamato", "defcom"]
}

variable "vm_ips" {
  description = "VM IP addresses with CIDR notation"
  type        = list(string)
  default     = ["192.168.15.20/24", "192.168.15.21/24", "192.168.15.22/24"]
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.15.1"
}

variable "dns" {
  description = "DNS server"
  type        = string
  default     = "8.8.8.8"
}

variable "template_id" {
  description = "Proxmox template VM ID"
  type        = number
  default     = 9000
}
