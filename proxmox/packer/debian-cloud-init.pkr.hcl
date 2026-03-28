packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "debian" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  # VM Configuration
  vm_id                = var.template_id
  vm_name              = var.template_name
  template_description = "Debian 13 template with qemu-guest-agent built with Packer"
  qemu_agent           = false  # Installed via provisioner, enabled for template use

  # ISO Configuration
  iso_file         = "local:iso/debian-13.3.0-amd64-DVD-1.iso"
  iso_storage_pool = "local"
  unmount_iso      = true

  # Hardware Configuration
  cores   = 2
  memory  = 2048
  sockets = 1

  # Disk Configuration
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "100G"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  # Network Configuration
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Boot Configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "debconf/frontend=noninteractive <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "fb=false <wait>",
    "install <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "locale=en_US.UTF-8 <wait>",
    "netcfg/get_hostname=debian <wait>",
    "netcfg/get_domain=localdomain <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "<enter>"
  ]

  http_directory = "."

  # SSH Configuration
  ssh_host             = "192.168.15.250"
  ssh_username         = "cflor"
  ssh_password         = "debian"
  ssh_port             = 22
  ssh_timeout          = "30m"
  ssh_wait_timeout     = "30m"
  ssh_handshake_attempts = 100

  # Conversion to template
  template_name = var.template_name
}

build {
  sources = ["source.proxmox-iso.debian"]

  # Install qemu-guest-agent
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent",
      "sudo systemctl enable qemu-guest-agent"
    ]
  }

  # Add SSH public key for homelab
  provisioner "shell" {
    inline = [
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDv197U2IvGjq4rImo3sRqE4oGko/pksOXnMVvr8QW0Vfl6F3iMjPZGat0+zQUuoQy8PgapJ8zEM8GnjxcjdIIlKqqOUA2j1yLmFxtSsI9HkrCNAK0FlfUGTH4gRHZUMCrCfXGaeRbuLiecSAAzpCrkMrQsfYZTWz5d/ZkbKzuoGPbkjbhcToV/o+o9Yiua7lRVBZ97QH4fK65KbEx6IOy+QC6Gu/8FGIwLOaCgV2O7cKfLpwDA2M+FF7hyvU/MsoMb4MaWjeau23DOALcdwVpTaG6pagGehCP6bh6XJ2yKJmt1QO+6ch+c/MRxNq2VcdLVACuQjKxF6ondeOrsTwhhvtmGkSQGyR734mllUXv9hC12OdkrhMt33uOuV1y43x1hC4jWUx9rX4JMN+zkCPrgUn2DPNNpNJkWbBpBXf3ZVa1rHHDS1HlqeqcV7K3o166N7gZkf6iWrJEFdhKtRPAgwK0gYBVDOifaoL8Cin/4GRrMVLed+MQ8CN5XPkdWLNs= cflor@cflor' > ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys"
    ]
  }

  # Cleanup - remove machine-specific data
  provisioner "shell" {
    inline = [
      "sudo rm -f /var/log/wtmp /var/log/btmp",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "rm -f ~/.bash_history",
      "sudo rm -f /root/.bash_history"
    ]
  }
}
