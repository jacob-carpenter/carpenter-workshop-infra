#!/bin/bash
set -e

# Install K3s Worker Node
# This script sets up a K3s agent (worker) node

echo "=== Starting K3s Worker Node Installation ==="

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget apt-transport-https ca-certificates awscli

# Wait for control plane to be ready and token to be available
echo "Waiting for control plane to be ready..."
sleep 60

# Retrieve K3s token from SSM Parameter Store
# Try both paths for backward compatibility
MAX_RETRIES=20
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Try new path first
  K3S_TOKEN=$(aws ssm get-parameter \
    --name "carpenter-workshop-${ENVIRONMENT}-k3s-token" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region ${AWS_REGION} 2>/dev/null || echo "")

  if [ -n "$K3S_TOKEN" ]; then
    echo "Successfully retrieved K3s token"
    break
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Waiting for K3s token... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 30
done

if [ -z "$K3S_TOKEN" ]; then
  echo "ERROR: Failed to retrieve K3s token from SSM"
  exit 1
fi

# Get EC2 instance metadata for cloud provider
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Install K3s agent with AWS cloud provider
# Note: provider-id must be in format: aws:///ZONE/INSTANCE_ID
curl -sfL https://get.k3s.io | K3S_URL=https://${CONTROL_PLANE_IP}:6443 K3S_TOKEN=$K3S_TOKEN sh -s - agent \
  --node-name worker-${WORKER_INDEX} \
  --kubelet-arg="cloud-provider=external" \
  --kubelet-arg="provider-id=aws:///$${AVAILABILITY_ZONE}/$${INSTANCE_ID}"

echo "=== K3s Worker Node Installation Complete ==="

# Wait for node to be registered and then apply worker label
echo "Waiting for node to be registered..."
sleep 30

# Label the node as a worker
# This uses the local k3s kubectl with server credentials
MAX_LABEL_RETRIES=5
LABEL_RETRY_COUNT=0
while [ $LABEL_RETRY_COUNT -lt $MAX_LABEL_RETRIES ]; do
  if /usr/local/bin/k3s kubectl label node worker-${WORKER_INDEX} node-role.kubernetes.io/worker=true --overwrite --kubeconfig=/var/lib/rancher/k3s/agent/kubeconfig.yaml 2>/dev/null; then
    echo "Successfully labeled node as worker"
    break
  fi

  LABEL_RETRY_COUNT=$((LABEL_RETRY_COUNT + 1))
  echo "Waiting to label node... (Attempt $LABEL_RETRY_COUNT/$MAX_LABEL_RETRIES)"
  sleep 10
done

if [ $LABEL_RETRY_COUNT -eq $MAX_LABEL_RETRIES ]; then
  echo "WARNING: Failed to label node as worker - label manually or it will be added by automation"
fi

echo "=== Worker Node Setup Complete ==="
