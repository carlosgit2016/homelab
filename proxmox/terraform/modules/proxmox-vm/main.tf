terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = var.mac_address
  }

  on_boot = true
}

resource "null_resource" "network_config" {
  depends_on = [
    proxmox_virtual_environment_vm.vm,
    var.depends_on_resource
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/configure-network.sh ${var.vm_id} '${split("/", var.static_ip)[0]}' '${var.gateway}' '${var.dns}' '${pathexpand(var.ssh_key_path)}' '${var.proxmox_host}'"
  }

  triggers = {
    vm_id = proxmox_virtual_environment_vm.vm.id
  }
}

resource "null_resource" "set_hostname" {
  depends_on = [null_resource.network_config]

  provisioner "local-exec" {
    command = "${path.module}/scripts/set-hostname.sh ${var.vm_id} '${var.hostname}' '${var.proxmox_host}'"
  }

  triggers = {
    hostname = var.hostname
  }
}
