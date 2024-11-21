#!/bin/bash

set -e

echo "Stopping containerd service..."
systemctl stop containerd || echo "Containerd service is not running."
systemctl disable containerd || echo "Containerd service was not enabled."

if [ -e /lib/systemd/system/containerd.service ]; then
    echo "Removing containerd systemd unit file..."
    rm -f /lib/systemd/system/containerd.service
    systemctl daemon-reload
fi

if [ -e /usr/local/bin/containerd ]; then
    echo "Removing containerd binary..."
    rm -f /usr/local/bin/containerd*
fi

if [ -e /usr/local/sbin/runc ]; then
    echo "Removing runc binary..."
    rm -f /usr/local/sbin/runc
fi

if [ -e /opt/cni/bin ]; then
    echo "Removing CNI plugins..."
    rm -rf /opt/cni/bin
fi

#Containerd cleanup

echo "Removing containerd configuration..."

if [ -e /opt/containerd ]; then
    rm -rf /opt/containerd
fi

if [ -e /var/lib/containerd ]; then
    rm -rf /var/lib/containerd
fi

if [ -e /etc/containerd ]; then
    rm -rf /etc/containerd
fi

if [ -e /etc/containerd ]; then
    echo "Removing containerd configuration..."
    rm -rf /etc/containerd
fi



echo "Cleaning up temporary files in /root/..."
rm -f /root/*

echo "Cleanup complete."
