terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.60"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://proxmox.cflor.org:8006/"
  api_token = "terraform-prov@pve!homelab=${var.proxmox_api_token_secret}"
  insecure  = true
}
