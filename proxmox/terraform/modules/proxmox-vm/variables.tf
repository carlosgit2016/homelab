variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "template_id" {
  description = "Template VM ID to clone from"
  type        = number
  default     = 9000
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "mac_address" {
  description = "MAC address for the network interface"
  type        = string
}

variable "static_ip" {
  description = "Static IP address with CIDR (e.g., 192.168.15.20/24)"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "dns" {
  description = "DNS server"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/homelab_id_rsa"
}

variable "proxmox_host" {
  description = "Proxmox host for SSH commands"
  type        = string
  default     = "proxmox.cflor.org"
}

variable "depends_on_resource" {
  description = "Resource to depend on for sequential execution"
  type        = any
  default     = null
}

variable "cpu_type" {
  description = "CPU type"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "hostname" {
  description = "Hostname to set on the VM"
  type        = string
  default     = ""
}
