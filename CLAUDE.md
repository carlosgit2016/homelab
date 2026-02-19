# CLAUDE.md

## What This Is

General-purpose Kubernetes homelab managed via GitOps. Currently deployed on Proxmox VMs running Debian 13. Ansible manages configuration of controlplane, worker nodes, and ArgoCD bootstrap. After initial deployment, ArgoCD self-manages and watches this repo (public GitHub) to deploy applications via GitOps. Includes media management (Jackett, qBittorrent, Radarr), monitoring (Prometheus), and infrastructure (nginx ingress, Longhorn storage).

## Cluster Topology

- **phoenix** (192.168.15.20) — 6GB RAM, 4 vCPU — Control Plane
- **yamato** (192.168.15.21) — 4GB RAM, 2 vCPU — Worker Node
- **defcom** (192.168.15.22) — 4GB RAM, 2 vCPU — Worker Node
- API endpoint: `192.168.15.20:6443`
- GitHub repo: `https://github.com/carlosgit2016/homelab.git`

## Repository Structure

```
proxmox/                        # VM infrastructure (optional)
├── packer/                     # Debian cloud-init template
│   ├── debian-cloud-init.pkr.hcl
│   └── preseed.cfg
└── terraform/                  # Provision 3 VMs from template
    └── modules/proxmox-vm/

ansible/                        # Configuration management
├── inventory.yaml              # Host inventory (controlplane, nodes groups)
├── controlplane.yaml           # Bootstrap K8s control plane
├── nodes.yaml                  # Configure and join worker nodes
├── argocd.yaml                 # Deploy ArgoCD
├── reset.yaml                  # Full cluster teardown
├── shutdown.yaml               # Graceful node shutdown
├── info.yaml                   # Cluster info gathering
└── roles/                      # Reusable roles
    ├── common/                 # System setup (packages, swap, cgroups, IP forwarding)
    ├── sourcesupdate/          # APT repository configuration
    ├── containerd/             # Container runtime (containerd + runc)
    ├── crictl/                 # CRI tools
    ├── k8stools/               # kubectl, kubeadm, kubelet
    ├── controlplane/           # kubeadm init + Calico CNI + Helm
    ├── joincluster/            # Worker node cluster join
    ├── argocd/                 # ArgoCD Helm deployment
    └── cleanup/                # Cluster reset/cleanup

manifests/                      # Kubernetes manifests (GitOps source of truth)
├── root.application.yaml       # ArgoCD root app — syncs all applications/*.application.yaml
├── applications/               # ArgoCD Application CRDs
│   ├── argocd.application.yaml
│   ├── nginx.application.yaml
│   ├── longhorn.application.yaml
│   ├── metrics-server.application.yaml
│   ├── kube-prometheus.yaml
│   ├── jackett.application.yaml
│   ├── qbittorrent.application.yaml
│   ├── radarr.application.yaml
│   └── rbac.application.yaml
├── nginx/                      # Ingress controller Helm values
├── longhorn/                   # Distributed storage Helm values
├── metrics-server/             # Resource metrics Helm values
├── jackett/                    # Indexer proxy (StatefulSet + Ingress)
├── qBittorrent/                # BitTorrent client (Deployment, hostNetwork)
├── radarr/                     # Movie manager (Deployment + PVC)
└── rbac/                       # RBAC ClusterRoleBindings

scripts/                        # Utility scripts
└── create-k8s-user.sh          # Generate kubeconfig for new users
```

## Initial Setup

1. **(Optional) Provision VMs**: Packer creates Debian 13 template on Proxmox (VM ID 9000). Terraform provisions 3 VMs from template. See `proxmox/README.md`.

2. **Run Ansible playbooks** (from `ansible/` directory):
   ```bash
   ansible-playbook -i inventory.yaml controlplane.yaml  # Bootstrap control plane
   ansible-playbook -i inventory.yaml nodes.yaml         # Join worker nodes
   ansible-playbook -i inventory.yaml argocd.yaml        # Deploy ArgoCD
   ```

3. **Create user**:
   ```bash
   ./scripts/create-k8s-user.sh <username>  # Generates kubeconfig
   ```

## How Deployment Works

1. **Ansible provisions infrastructure**: playbooks bootstrap nodes, install container runtime, initialize K8s control plane, join workers
2. **ArgoCD self-manages**: after initial Helm deployment, `manifests/applications/argocd.application.yaml` takes over
3. **ArgoCD watches this repo**: `root.application.yaml` syncs all `manifests/applications/*.application.yaml` files from public GitHub
4. **Each Application CRD** points to either a Helm chart repo (with local values files) or raw manifests in this repo
5. **Changes are deployed by pushing to `main`** — ArgoCD detects and syncs automatically

## Commands

```bash
# Ansible — run from ansible/ directory
ansible-playbook -i inventory.yaml controlplane.yaml    # Bootstrap control plane
ansible-playbook -i inventory.yaml nodes.yaml            # Join worker nodes
ansible-playbook -i inventory.yaml argocd.yaml           # Deploy ArgoCD
ansible-playbook -i inventory.yaml reset.yaml            # Tear down cluster
ansible-playbook -i inventory.yaml shutdown.yaml         # Shutdown nodes
ansible-playbook -i inventory.yaml info.yaml             # Gather cluster info

# Linting
ansible-lint                                             # Lint Ansible playbooks/roles

# Pre-commit
pre-commit run --all-files                               # Run all pre-commit hooks
```

## Stack

- **Kubernetes**: 1.31 (kubeadm)
- **Container runtime**: containerd 2.0.0, runc 1.2.2
- **CNI**: Calico 3.29.0
- **ArgoCD**: 7.6.12+ (Helm)
- **Storage**: Longhorn 1.7.1
- **Ingress**: nginx-ingress-controller (bitnami/11.6.0)
- **Monitoring**: kube-prometheus 66.2.1
- **OS**: Debian 13 (cloud-init based template)
- **Hardware**: Proxmox VMs: phoenix (6GB/4vCPU), yamato (4GB/2vCPU), defcom (4GB/2vCPU)

## Things That Will Bite You

- **ArgoCD root app pattern**: `root.application.yaml` only includes files matching `*.application.yaml` in `manifests/applications/`. If your file doesn't match that glob, ArgoCD won't pick it up. Note `kube-prometheus.yaml` breaks this convention — it works but is inconsistent.
- **Helm values via two-source pattern**: Application CRDs reference both a Helm chart repo and this Git repo for values. The values path must match the directory structure under `manifests/`.
- **hostNetwork on qBittorrent**: Uses the host network directly — port conflicts with other hostNetwork pods will silently fail.
- **Node affinity on Jackett**: The StatefulSet prefers non-control-plane nodes. If all workers are unavailable, scheduling may stall.
- **kube-prometheus in wrong namespace**: The monitoring stack deploys to the `jackett` namespace instead of a dedicated monitoring namespace. This will be fixed in a future deployment.
- **Ansible roles use environment variables for versions**: `containerd`, `runc`, and CNI plugin versions are set as env vars in role tasks — not in a central variables file.

## Code Conventions

- **Git commits**: `type(scope): message` format. Types: `feat`, `chore`, `fix`. Scope is the affected component (e.g., `ansible`, `qbittorrent`, `radarr`).
- **YAML indentation**: 2 spaces throughout.
- **Ansible tasks**: descriptive present-tense names. Use `become: true` for privilege escalation. Use `changed_when` to control change reporting.
- **Ansible lint**: skips `run-once[play]` and `package-latest` rules (see `ansible/ansible-lint.yaml`).
- **Pre-commit hooks**: trailing whitespace, end-of-file fixer, YAML validation, large file check. The `kubeadm-clusterconfig.yaml` is excluded from YAML checking.
- **Application manifests**: name files as `<app>.application.yaml` for ArgoCD discovery. Use `CreateNamespace=true` in sync options.
- **No automated tests**: validation is through `ansible-lint`, `pre-commit`, and manual verification.
