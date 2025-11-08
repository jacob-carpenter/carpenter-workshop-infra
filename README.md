## Deployment

### Production Deployment

#### 1. Terraform Infrastructure

Deploy the AWS infrastructure (VPC, EC2 instances for K3s, ECR):

```bash
cd infrastructure/terraform/environments/prod

terraform init
terraform plan
terraform apply
```

#### 2. Setup KUBECONFIG

Get the kubeconfig from AWS Systems Manager:

```bash
# Get kubeconfig from Parameter Store
aws ssm get-parameter \
     --name /carpenter-workshop/prod/kubeconfig \
     --with-decryption \
     --query 'Parameter.Value' \
     --output text \
     --region us-east-1 > ~/kubeconfig

# Update kubeconfig with control plane public IP (from terraform output)
export CONTROL_PLANE_IP=$(cd infrastructure/terraform/environments/prod && terraform output -raw control_plane_public_ip)
sed -i "s|127.0.0.1|$CONTROL_PLANE_IP|g" ~/kubeconfig

# Set KUBECONFIG environment variable
export KUBECONFIG=~/kubeconfig

# Verify cluster connectivity
kubectl get nodes
```

#### 3. Deploy Cluster Baseline

Install core cluster services (AWS Load Balancer Controller, external-dns, cert-manager, metrics-server):

```bash
cd kubernetes/cluster-baseline

# Add Helm repositories
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add eks https://aws.github.io/eks-charts
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

# Update dependencies
helm dependency update

# Install cluster baseline
helm install cluster-baseline . --values values.yaml --namespace carpenter-workshop --create-namespace

# Verify AWS Load Balancer Controller is running
kubectl get pods -n carpenter-workshop -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify external-dns is running
kubectl get pods -n carpenter-workshop -l app.kubernetes.io/name=external-dns
```

### TODO

[] Update reusable app helm common-app chart to host as github page for the repository and use it for the import-map-deployer
[] Clean up the values.yaml to extract out commonly changing environment specific concepts to a much cleaner location
[] Update to use github actions to apply infra and helm install/upgrade upon infra or helm chart changes
[] Validate full infra rebuild prior to main merge
[] Update the readmes and add arch diagrams