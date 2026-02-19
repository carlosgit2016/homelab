# Proxmox VM Infrastructure

This directory contains Packer and Terraform configurations for creating and provisioning Debian VMs on Proxmox for the homelab Kubernetes cluster.

## Overview

The infrastructure is built in two phases:

1. **Packer**: Creates a reusable Debian 13 cloud-init template (VM ID 9000)
2. **Terraform**: Provisions 3 VMs from the template with specific configurations

## Prerequisites

- Packer 1.8+ installed
- Terraform 1.0+ installed
- Proxmox VE server accessible at `proxmox.cflor.org:8006`
- Proxmox API token with VM provisioning permissions
- SSH key pair at `~/.ssh/homelab_id_rsa` and `~/.ssh/homelab_id_rsa.pub`
- Debian 13.3.0 DVD ISO uploaded to Proxmox (`local:iso/debian-13.3.0-amd64-DVD-1.iso`)

## VM Configuration

| VM       | Role          | IP             | RAM  | Cores | Disk |
|----------|---------------|----------------|------|-------|------|
| phoenix  | Control Plane | 192.168.15.20  | 6GB  | 4     | 64GB |
| yamato   | Worker        | 192.168.15.21  | 4GB  | 2     | 32GB |
| defcom   | Worker        | 192.168.15.22  | 4GB  | 2     | 32GB |

Network: vmbr0 bridge, gateway 192.168.15.1, DNS 8.8.8.8

## Setup

### 1. Configure Secrets

**For Packer:**
```bash
cd packer
cp auto.pkrvars.hcl.example auto.pkrvars.hcl
# Edit auto.pkrvars.hcl with your Proxmox API token
```

**For Terraform:**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox API token
```

### 2. Build Packer Template

This creates a reusable Debian cloud-init template (VM ID 9000):

```bash
cd packer
packer init debian-cloud-init.pkr.hcl
packer validate debian-cloud-init.pkr.hcl
packer build debian-cloud-init.pkr.hcl
```

**Expected time:** 15-20 minutes

The build process:
1. Boots Debian installer from ISO
2. Automates installation via preseed.cfg
3. Installs cloud-init, qemu-guest-agent, openssh-server
4. Cleans up logs and machine-specific data
5. Converts to template

**Verification:**
```bash
ssh proxmox.cflor.org "qm list | grep 9000"
```

You should see VM 9000 with name `debian-13-cloudinit-template`.

### 3. Provision VMs with Terraform

This clones 3 VMs from the template:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Expected time:** 3-5 minutes

Wait 3-5 minutes after apply for cloud-init to configure networking and SSH on each VM.

**Verification:**
```bash
# Test SSH access
ssh -i ~/.ssh/homelab_id_rsa debian@192.168.15.20
ssh -i ~/.ssh/homelab_id_rsa debian@192.168.15.21
ssh -i ~/.ssh/homelab_id_rsa debian@192.168.15.22

# Check cloud-init completion
ssh -i ~/.ssh/homelab_id_rsa debian@192.168.15.20 "cloud-init status"
# Should show: status: done
```

### 4. Bootstrap Kubernetes Cluster

Update Ansible inventory (already configured for these VMs) and run playbooks:

```bash
cd ../ansible
ansible all -i inventory.yaml -m ping
ansible-playbook -i inventory.yaml controlplane.yaml  # Setup phoenix
ansible-playbook -i inventory.yaml nodes.yaml         # Join yamato and defcom
ansible-playbook -i inventory.yaml argocd.yaml        # Deploy ArgoCD
```

## Directory Structure

```
proxmox/
├── packer/
│   ├── debian-cloud-init.pkr.hcl     # Packer template definition
│   ├── preseed.cfg                    # Debian automated installer config
│   ├── variables.pkr.hcl              # Variable declarations
│   ├── auto.pkrvars.hcl.example       # Example secrets file (committed)
│   └── auto.pkrvars.hcl               # Actual secrets (gitignored)
├── terraform/
│   ├── main.tf                        # Provider and VM resources
│   ├── variables.tf                   # Variable declarations
│   ├── outputs.tf                     # Output VM IPs and IDs
│   ├── terraform.tfvars.example       # Example secrets (committed)
│   └── terraform.tfvars               # Actual secrets (gitignored)
└── README.md                          # This file
```

## Rebuilding Template

To rebuild the Packer template (e.g., to update packages or configuration):

```bash
# Delete existing template
ssh proxmox.cflor.org "qm destroy 9000"

# Rebuild
cd packer
packer build debian-cloud-init.pkr.hcl
```

## Destroying VMs

```bash
cd terraform
terraform destroy
```

This removes the VMs but keeps the template for future use.

## Troubleshooting

### Packer build fails

- Check Proxmox API token has correct permissions
- Verify ISO file exists: `ssh proxmox.cflor.org "ls -la /var/lib/vz/template/iso/debian-13.3.0-amd64-DVD-1.iso"`
- Check Packer logs for preseed errors

### Cloud-init doesn't configure network

- Wait 5 minutes after VM creation
- Check cloud-init logs: `ssh debian@<ip> "sudo cat /var/log/cloud-init.log"`
- Verify SSH key is correct in terraform.tfvars

### SSH connection refused

- Ensure cloud-init has finished: `ssh debian@<ip> "cloud-init status"`
- Check VM console in Proxmox web UI for errors
- Verify static IP configuration: `ssh debian@<ip> "ip addr"`

### Terraform apply fails with "template not found"

- Verify template exists: `ssh proxmox.cflor.org "qm list | grep 9000"`
- Run Packer build first to create template

## Notes

- Template is idempotent - can rebuild anytime without affecting existing VMs
- VMs use full clones (not linked clones) for independence
- Cloud-init runs once on first boot to configure hostname, network, and SSH
- Proxmox uses self-signed cert, hence `insecure_skip_tls_verify = true` in configs
- Both Packer and Terraform use the same API token: `terraform-prov@pve!homelab`
- SSH user is `debian` with passwordless sudo access
- Do NOT commit `auto.pkrvars.hcl` or `terraform.tfvars` - they contain secrets

## API Token Setup

If you need to create a new Proxmox API token:

```bash
# In Proxmox web UI:
# 1. Datacenter → Permissions → API Tokens
# 2. Add token for user terraform-prov@pve
# 3. Token ID: homelab
# 4. Privilege Separation: NO (unchecked)
# 5. Copy the token secret immediately (cannot be retrieved later)
```

Required permissions for token:
- VM.Allocate
- VM.Clone
- VM.Config.Disk
- VM.Config.CPU
- VM.Config.Memory
- VM.Config.Network
- Datastore.AllocateSpace
- SDN.Use
