#!/bin/bash

set -e

# Another easy option and probably the one I should went with is to install containerd using apt-get

pushd /root/

# Containerd installation
curl -SsL -O https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-linux-arm64.tar.gz
sha256sum containerd-$CONTAINERD_VERSION-linux-arm64.tar.gz
tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-linux-arm64.tar.gz

# Systemd containerd unit configuration
curl -SsL -O https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

# Runc download and configuration
curl -SsL -O https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.arm64
sha256sum runc.sha256sum
install -m 755 runc.arm64 /usr/local/sbin/runc

# CNI download and configuration
curl -SsL -O https://github.com/containernetworking/plugins/releases/download/v$CNI_PLUGIN_VERSION/cni-plugins-linux-arm64-v$CNI_PLUGIN_VERSION.tgz
sha256sum "cni-plugins-linux-arm64-v$CNI_PLUGIN_VERSION.tgz"
if [ ! -e /opt/cni/bin ]; then
    mkdir /opt/cni/bin
fi
tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v$CNI_PLUGIN_VERSION.tgz

# Generating containerd initial config
if [ ! -e /etc/containerd ]; then
    mkdir /etc/containerd
fi

popd

systemctl restart containerd

# update: 2024-11-20
