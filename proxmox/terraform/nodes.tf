# Yamato - Worker (4GB RAM, 2 cores)
module "yamato" {
  source = "./modules/proxmox-vm"

  vm_name              = "yamato"
  vm_id                = 101
  cores                = 2
  memory               = 4096
  mac_address          = "BC:24:11:21:00:01"
  static_ip            = var.vm_ips[1]
  gateway              = var.gateway
  dns                  = var.dns
  hostname             = "yamato"
  depends_on_resource  = module.phoenix.network_config_id
}

# Defcom - Worker (4GB RAM, 2 cores)
module "defcom" {
  source = "./modules/proxmox-vm"

  vm_name              = "defcom"
  vm_id                = 102
  cores                = 2
  memory               = 4096
  mac_address          = "BC:24:11:22:00:01"
  static_ip            = var.vm_ips[2]
  gateway              = var.gateway
  dns                  = var.dns
  hostname             = "defcom"
  depends_on_resource  = module.yamato.network_config_id
}
