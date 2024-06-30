## Homelab

Homelab with Kubernetes using Raspberry PIs 5

### Stack
- 3 Raspberry PIs 5
- Debian Bookworm
- Ansible
- containerd
- Kubernetes

### Giving a user access to the cluster

#### Create a private key
```bash
openssl genrsa -out username.key 2048
```

#### Create a CSR
```bash
openssl req -new -key username.key -out username.csr -subj "/CN=username"
```

#### Create a CertificateSigningRequest k8s object

Encode the username csr
```bash
export csr=$(cat username.csr | base64 | tr -d '\n')
```

Create a new file with the following yaml and save to `username-csr.yaml`
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: username
spec:
  request: <base64-csr-here>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - digital signature
  - key encipherment
  - client auth
```

Place the encoded csr in the CRT request
```base
sed -i "s|\(request: \).*|\1$csr|" username-csr.yaml
```

#### Approve the csr and get the certificate
```bash
kubectl certificate approve username
kubectl get csr cflor -ojsonpath='{.status.certificate}'
```

#### Configure kube config with the ca, crt and the private key

Example of kube config
```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/cflor/.homelab/ca.crt
    server: https://192.168.1.9:8080
  name: home
contexts:
- context:
    cluster: home
    namespace: default
    user: cflor
  name: home
current-context: home
kind: Config
preferences: {}
users:
- name: cflor
  user:
    client-certificate: /home/cflor/.homelab/cflor.crt
    client-key: /home/cflor/.homelab/cflor.key
```

### TODO
- Verify the admin.conf kubeconfig to understand - DONE
- Sign a certificate to use from the personal laptop - DONE
- Configure the other instances to join the cluster
- Deploy ArgoCD on it
- Deploy jackett
- Start working in the personal blogi
- Configure Samba in k8s with PV/PVC

### Ideas to host in the cluster
- Jackett
- Personal blog
- Plex server / DNLA
- Cripto Miner
