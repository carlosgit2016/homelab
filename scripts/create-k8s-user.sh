#!/bin/bash
set -e

USERNAME="${1:-cflor}"
CONTROL_PLANE="${2:-192.168.15.20}"
KUBECONFIG="/etc/kubernetes/admin.conf"
OUTPUT_DIR="$HOME/.kube/contexts"

echo "Creating Kubernetes user: $USERNAME"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate private key
openssl genrsa -out "$OUTPUT_DIR/${USERNAME}.key" 2048

# Generate CSR
openssl req -new -key "$OUTPUT_DIR/${USERNAME}.key" -out "/tmp/${USERNAME}.csr" -subj "/CN=${USERNAME}"

# Encode CSR
CSR_BASE64=$(cat "/tmp/${USERNAME}.csr" | base64 | tr -d '\n')

# Create K8s CSR manifest
cat > "/tmp/${USERNAME}-k8s-csr.yaml" <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

# Copy CSR manifest to control plane
scp "/tmp/${USERNAME}-k8s-csr.yaml" "${CONTROL_PLANE}:/tmp/${USERNAME}-k8s-csr.yaml"

# Apply CSR
ssh "$CONTROL_PLANE" "kubectl apply -f /tmp/${USERNAME}-k8s-csr.yaml --kubeconfig=$KUBECONFIG"

# Approve CSR
ssh "$CONTROL_PLANE" "kubectl certificate approve $USERNAME --kubeconfig=$KUBECONFIG"

# Wait for certificate
sleep 2

# Get signed certificate
ssh "$CONTROL_PLANE" "kubectl get csr $USERNAME -o jsonpath='{.status.certificate}' --kubeconfig=$KUBECONFIG" | base64 -d > "$OUTPUT_DIR/${USERNAME}.crt"

# Copy CA certificate from control plane
scp "${CONTROL_PLANE}:/etc/kubernetes/pki/ca.crt" "$OUTPUT_DIR/ca.crt"

# Generate kubeconfig
cat > "$OUTPUT_DIR/${USERNAME}-config" <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority: ${OUTPUT_DIR}/ca.crt
    server: https://192.168.15.20:6443
  name: homelab
contexts:
- context:
    cluster: homelab
    namespace: default
    user: ${USERNAME}
  name: homelab
current-context: homelab
kind: Config
preferences: {}
users:
- name: ${USERNAME}
  user:
    client-certificate: ${OUTPUT_DIR}/${USERNAME}.crt
    client-key: ${OUTPUT_DIR}/${USERNAME}.key
EOF

# Set permissions
chmod 600 "$OUTPUT_DIR/${USERNAME}.key" "$OUTPUT_DIR/${USERNAME}.crt" "$OUTPUT_DIR/${USERNAME}-config"

# Cleanup
rm -f "/tmp/${USERNAME}.csr" "/tmp/${USERNAME}-k8s-csr.yaml"
ssh "$CONTROL_PLANE" "rm -f /tmp/${USERNAME}-k8s-csr.yaml"

echo "✓ User created successfully"
echo "  Kubeconfig: $OUTPUT_DIR/${USERNAME}-config"
echo "  Control plane: $CONTROL_PLANE"
echo ""
echo "Test with: kubectl --kubeconfig=$OUTPUT_DIR/${USERNAME}-config get nodes"
