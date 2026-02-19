#!/bin/bash
set -e

# Parameters from Terraform
VM_ID=$1
HOSTNAME=$2
PROXMOX_HOST=$3

if [ -z "$HOSTNAME" ]; then
  echo "No hostname provided for VM $VM_ID, skipping..."
  exit 0
fi

echo "Setting hostname to $HOSTNAME for VM $VM_ID..."
ssh root@$PROXMOX_HOST "qm guest exec $VM_ID -- bash -c 'hostnamectl set-hostname $HOSTNAME && echo $HOSTNAME > /etc/hostname'" 2>/dev/null

echo "Hostname $HOSTNAME successfully set for VM $VM_ID"
