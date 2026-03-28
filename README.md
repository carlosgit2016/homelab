## Homelab

General-purpose Kubernetes homelab for self-hosted services and infrastructure experimentation. Managed via GitOps with ArgoCD. Configuration and bootstrapping handled by Ansible. All manifests and infrastructure code versioned in this repository.

### Current Infrastructure

**Proxmox VMs running Debian 13**

- **phoenix** (192.168.15.20) - 6GB RAM, 4 vCPU - Control Plane
- **yamato** (192.168.15.21) - 4GB RAM, 2 vCPU - Worker Node
- **defcom** (192.168.15.22) - 4GB RAM, 2 vCPU - Worker Node

Provisioned via Packer template + Terraform. See `proxmox/README.md`.

### Infrastructure Overview

```mermaid
graph LR
    subgraph Hardware["Hardware"]
        HW["Intel Core i7-1185G7 (11th Gen)<br/>8 cores @ 3.00GHz<br/>15GB RAM | 94GB Storage"]
    end

    subgraph Proxmox["Proxmox VE"]
        PVE["Proxmox VE<br/>Linux 6.17.2-1-pve"]
    end

    subgraph VMs["Virtual Machines - Debian 13"]
        VM1["phoenix<br/>192.168.15.20<br/>6GB RAM | 4 vCPU<br/>Control Plane"]
        VM2["yamato<br/>192.168.15.21<br/>4GB RAM | 2 vCPU<br/>Worker Node"]
        VM3["defcom<br/>192.168.15.22<br/>4GB RAM | 2 vCPU<br/>Worker Node"]
    end

    subgraph K8s["Kubernetes Layer - v1.31"]
        Runtime["Container Runtime<br/>containerd 2.0.0<br/>runc 1.2.2"]
        CNI["Network<br/>Calico CNI 3.29.0"]
        API["Kubernetes API<br/>192.168.15.20:6443"]
    end

    subgraph Apps["Applications"]
        subgraph Infra["Infrastructure and CI/CD"]
            ArgoCD["ArgoCD 7.6.12+<br/>GitOps Controller"]
            Nginx["Nginx Ingress<br/>HTTP/HTTPS Routing"]
            Longhorn["Longhorn 1.7.1<br/>Distributed Storage"]
            Metrics["Metrics Server<br/>Resource Metrics"]
            Prometheus["Kube-Prometheus 66.2.1<br/>Monitoring Stack"]
        end
        subgraph Media["Apps"]
            Jackett["Jackett<br/>:30319"]
            qBit["qBittorrent<br/>:30321"]
            Radarr["Radarr<br/>:30320"]
        end
    end

```

### Stack
- Kubernetes 1.31 (kubeadm)
- containerd 2.0.0 / runc 1.2.2
- Calico CNI 3.29.0
- ArgoCD 7.6.12+ (Helm)
- Longhorn 1.7.1 (distributed block storage)
- nginx-ingress (bitnami/11.6.0)
- kube-prometheus 66.2.1 + Metrics Server

### Deployed Applications

**Infrastructure**
- **ArgoCD** - GitOps continuous delivery controller
- **Nginx Ingress** - HTTP/HTTPS routing and load balancing
- **Longhorn** - Distributed block storage with replication
- **Metrics Server** - Resource metrics (CPU/memory) for HPA and kubectl top
- **Kube-Prometheus** - Full monitoring stack (Prometheus, Grafana, Alertmanager)

**Media Management**
- **Jackett** - Torrent indexer proxy/aggregator
- **qBittorrent** - BitTorrent client (hostNetwork mode)
- **Radarr** - Movie collection manager and automation

### Initial Setup

1. **(Optional) Provision Proxmox VMs**: Use Packer to create Debian template, Terraform to provision 3 VMs (phoenix, yamato, defcom). See `proxmox/README.md`.

2. **Run Ansible playbooks** (from `ansible/` directory):
   ```bash
   cd ansible/
   ansible-playbook -i inventory.yaml controlplane.yaml
   ansible-playbook -i inventory.yaml nodes.yaml
   ansible-playbook -i inventory.yaml argocd.yaml
   ```

3. **Create Kubernetes user**:
   ```bash
   ./scripts/create-k8s-user.sh <user> # left empty for cflor
   ```

### Access

**ArgoCD** - https://192.168.15.20:30443
- Username: `admin`
- Password: `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d`

**Jackett** - http://192.168.15.20:30319

**qBittorrent** - http://192.168.15.20:30321

**Radarr** - http://192.168.15.20:30320

**Longhorn** - http://192.168.15.20:30318

### Configure Kubelet TLS Bootstrap

```bash
ansible all -b -i inventory.yaml -a "echo 'serverTLSBootstrap: true' >> /var/lib/kubelet/config.yaml" -m shell
ansible all -b -i inventory.yaml -a "sudo systemctl restart kubelet" -m shell
```

### Documentation

For detailed documentation on repository structure, deployment workflows, gotchas, and code conventions, see [CLAUDE.md](./CLAUDE.md).
