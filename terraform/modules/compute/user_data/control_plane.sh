#!/bin/bash
set -e

# Install K3s Control Plane
# This script sets up a K3s server (control plane) node

echo "=== Starting K3s Control Plane Installation ==="

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget apt-transport-https ca-certificates awscli

# Get EC2 instance metadata for cloud provider
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION=$(echo $AVAILABILITY_ZONE | sed 's/[a-z]$//')

# Install K3s server with AWS cloud provider
# Note: provider-id must be in format: aws:///ZONE/INSTANCE_ID
curl -sfL https://get.k3s.io | sh -s - server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644 \
  --node-name control-plane \
  --tls-san $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \
  --tls-san $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) \
  --kubelet-arg="cloud-provider=external" \
  --kubelet-arg="provider-id=aws:///$${AVAILABILITY_ZONE}/$${INSTANCE_ID}"

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
sleep 30

# Verify installation
kubectl get nodes

# Get the node token for workers
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
echo "K3S_TOKEN: $K3S_TOKEN"

# Store token in SSM Parameter Store for workers to retrieve
# Use simpler parameter name format (no leading slash, hyphen-separated)
aws ssm put-parameter \
  --name "carpenter-workshop-${ENVIRONMENT}-k3s-token" \
  --value "$K3S_TOKEN" \
  --type "SecureString" \
  --overwrite \
  --region ${AWS_REGION} || true

# Store kubeconfig in SSM for remote access
aws ssm put-parameter \
  --name "carpenter-workshop-${ENVIRONMENT}-kubeconfig" \
  --value "$(cat /etc/rancher/k3s/k3s.yaml)" \
  --type "SecureString" \
  --overwrite \
  --region ${AWS_REGION} || true

echo "Node token and kubeconfig stored in SSM Parameter Store"

# Configure CoreDNS to use VPC DNS resolver for external queries
echo "=== Configuring CoreDNS for VPC DNS resolution ==="

# Get VPC CIDR and calculate VPC DNS server (VPC base + 2)
MAC=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
VPC_CIDR=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$${MAC}/vpc-ipv4-cidr-block)

# Calculate VPC DNS server (base IP + 2)
# For example: 10.0.0.0/16 -> 10.0.0.2
VPC_BASE=$(echo $${VPC_CIDR} | cut -d'/' -f1)
IFS='.' read -r i1 i2 i3 i4 <<< "$${VPC_BASE}"
VPC_DNS="$${i1}.$${i2}.$${i3}.$((i4 + 2))"

echo "VPC CIDR: $${VPC_CIDR}"
echo "VPC DNS Server: $${VPC_DNS}"

# Update CoreDNS ConfigMap to add VPC DNS forwarding
kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-backup.yaml

# Use the calculated VPC DNS in the CoreDNS config
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
      errors
      health {
        lameduck 30s
      }
      ready
      kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
        ttl 30
      }
      prometheus :9153
      forward . /etc/resolv.conf $${VPC_DNS}
      cache 30
      loop
      reload
      loadbalance
      import /etc/coredns/custom/*.override
    }
  NodeHosts: |
    127.0.0.1 localhost
    ::1 localhost ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    fe00::0 ip6-mcastprefix
    fe00::1 ip6-allnodes
    fe00::2 ip6-allrouters
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
EOF

# Restart CoreDNS to apply changes
kubectl rollout restart deployment coredns -n kube-system

# Wait for CoreDNS to be ready
echo "Waiting for CoreDNS to restart..."
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=120s || true

echo "=== CoreDNS configuration complete ==="

echo "=== K3s Control Plane Installation Complete ==="
