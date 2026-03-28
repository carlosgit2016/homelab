# Tool Reference

## kubectl

In-cluster mode — ServiceAccount token is auto-mounted at `/var/run/secrets/kubernetes.io/serviceaccount/`.
kubectl uses the in-cluster config automatically when `KUBERNETES_SERVICE_HOST` is set.

Common commands:
```bash
kubectl get pods -A                                    # all pods
kubectl get nodes                                      # node status
kubectl describe pod <name> -n <ns>                    # pod details
kubectl logs <name> -n <ns> --tail=50                  # recent logs
kubectl apply -f <file>                                # apply manifest
kubectl apply --dry-run=server -f <file>               # validate only
kubectl rollout status deploy/<name> -n <ns>           # watch rollout
```

## git (SSH)

SSH key at `/home/openclaw/.ssh/id_rsa` (mounted from `openclaw-ssh-key` Secret).
Always use SSH remote URLs:
```bash
git clone git@github.com:carlosgit2016/homelab.git /workspace/homelab
git -C /workspace/homelab checkout -b fix/<description>
git -C /workspace/homelab add -A
git -C /workspace/homelab commit -m "fix(<scope>): <description>"
git -C /workspace/homelab push origin fix/<description>
```

## helm

```bash
helm list -A                    # list all releases
helm status <release> -n <ns>   # release status
helm diff upgrade ...           # preview changes (helm-diff plugin)
```

## argocd

```bash
argocd app list                          # all apps
argocd app get <name>                    # app details
argocd app sync <name>                   # trigger sync
argocd app diff <name>                   # show diff
```
ArgoCD server is in the `argocd` namespace. Use in-cluster service: `argocd-server.argocd.svc.cluster.local`

## calicoctl

```bash
calicoctl get nodes                      # calico node status
calicoctl get bgppeers                   # BGP peers
```

## kubeseal

```bash
kubeseal --fetch-cert \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  > /tmp/cert.pem

kubectl create secret generic <name> -n <ns> \
  --from-literal=KEY=VALUE \
  --dry-run=client -o yaml \
  | kubeseal --cert /tmp/cert.pem -o yaml \
  > sealed-secret.yaml
```

## ansible

```bash
cd /workspace/homelab/ansible
ansible-playbook -i inventory.yaml <playbook>.yaml
ansible-lint                             # lint playbooks
```

## pre-commit

```bash
cd /workspace/homelab
pre-commit run --all-files               # validate before committing
```
