#!/bin/bash
set -e

# Parameters from Terraform
VM_ID=$1
STATIC_IP=$2
GATEWAY=$3
DNS=$4
SSH_KEY_PATH=$5
PROXMOX_HOST=$6

echo "Waiting for VM $VM_ID to boot..."
sleep 30

# Get DHCP IP from guest agent
DHCP_IP=$(ssh root@$PROXMOX_HOST "qm guest cmd $VM_ID network-get-interfaces" 2>/dev/null | grep -oP '(?<="ip-address" : ")[^"]+' | grep -v '^127\|^::' | head -1)
echo "VM $VM_ID DHCP IP: $DHCP_IP"

# Clean SSH keys
ssh-keygen -R $DHCP_IP 2>/dev/null || true
ssh-keygen -R $STATIC_IP 2>/dev/null || true

# Write static IP configuration directly via guest exec
echo "Configuring static IP $STATIC_IP for VM $VM_ID..."
ssh root@$PROXMOX_HOST "qm guest exec $VM_ID -- bash -c 'cat > /etc/network/interfaces.d/ens18 <<EOF
auto ens18
iface ens18 inet static
    address $STATIC_IP
    netmask 255.255.255.0
    gateway $GATEWAY
    dns-nameservers $DNS
EOF
sync'" 2>/dev/null
sleep 2

# Reboot VM to apply new network configuration
ssh root@$PROXMOX_HOST "qm reboot $VM_ID" || true
echo "VM $VM_ID rebooting with static IP $STATIC_IP"
sleep 45

# Verify the static IP is applied
for i in {1..12}; do
  CURRENT_IP=$(ssh root@$PROXMOX_HOST "qm guest cmd $VM_ID network-get-interfaces" 2>/dev/null | grep -oP '(?<="ip-address" : ")[^"]+' | grep -v '^127\|^::' | head -1)
  if [ "$CURRENT_IP" = "$STATIC_IP" ]; then
    echo "VM $VM_ID successfully configured with static IP $STATIC_IP"
    exit 0
  fi
  echo "Waiting for IP to apply... (current: $CURRENT_IP, expected: $STATIC_IP, attempt $i/12)"
  sleep 5
done

echo "ERROR: VM $VM_ID failed to apply static IP. Current IP: $CURRENT_IP, Expected: $STATIC_IP"
exit 1
