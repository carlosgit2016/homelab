variable "proxmox_api_url" {
  type    = string
  default = "https://proxmox.cflor.org:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "template_name" {
  type    = string
  default = "debian-13-cloudinit-template"
}

variable "template_id" {
  type    = number
  default = 9000
}
