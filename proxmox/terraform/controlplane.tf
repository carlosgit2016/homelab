# Phoenix - Control Plane (6GB RAM, 4 cores)
module "phoenix" {
  source = "./modules/proxmox-vm"

  vm_name     = "phoenix"
  vm_id       = 100
  cores       = 4
  memory      = 6144
  mac_address = "BC:24:11:20:00:01"
  static_ip   = var.vm_ips[0]
  gateway     = var.gateway
  dns         = var.dns
  hostname    = "phoenix"
  disk_size   = 150
}
