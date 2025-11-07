# Terraform Infrastructure

This directory contains Terraform configurations for deploying and managing K8s cluster infrastructure across multiple environments.

## Architecture Overview

The infrastructure is organized into:
- **Environments**: Environment-specific configurations (e.g., `prod`, `staging`, `dev`)
- **Modules**: Reusable infrastructure components shared across environments

### Module Structure

- **`modules/vpc`**: VPC, subnets, internet gateway, and routing
- **`modules/security`**: Security groups for control plane, workers, and ALB
- **`modules/alb`**: Application Load Balancer and target groups
- **`modules/compute`**: EC2 instances (K8s nodes), IAM roles, and user data scripts

### Environment Structure

Each environment directory (e.g., `environments/prod/`) contains:
- `main.tf`: Root module that composes infrastructure modules
- `variables.tf`: Environment-specific variable definitions
- `outputs.tf`: Output values from the deployment
- `terraform.tfvars.example`: Example configuration file
- `README.md`: Environment-specific documentation

## Prerequisites

1. **AWS CLI** installed and configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **SSH Key Pair** created in AWS (optional, for SSH access)
4. **S3 Backend** for Terraform state (create manually first)
5. **ACM Certificate** (optional, for HTTPS)

## Initial Setup (One-Time)

### 1. Create S3 Backend for State Management

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket carpenter-workshop-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket carpenter-workshop-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket carpenter-workshop-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name carpenter-workshop-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Create SSH Key Pair (Optional)

```bash
# Create a new SSH key pair
aws ec2 create-key-pair \
  --key-name carpenter-workshop-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/carpenter-workshop-key.pem

chmod 400 ~/.ssh/carpenter-workshop-key.pem
```

### 3. Create ACM Certificate (Optional, for HTTPS)

```bash
# Request a certificate
aws acm request-certificate \
  --domain-name carpenterworkshop.net \
  --validation-method DNS \
  --region us-east-1

# Follow the email/DNS validation process
# Note the Certificate ARN for later use
```

## Deploying an Environment

### Production Environment

```bash
# Navigate to production environment
cd environments/prod

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Save outputs
terraform output > outputs.txt
```

### Adding a New Environment (e.g., Staging)

To create a new environment:

1. **Copy the prod environment directory**:
   ```bash
   cp -r environments/prod environments/staging
   ```

2. **Update the backend configuration** in `environments/staging/main.tf`:
   ```hcl
   backend "s3" {
     bucket         = "carpenter-workshop-terraform-state"
     key            = "staging/terraform.tfstate"  # Change key
     region         = "us-east-1"
     encrypt        = true
     dynamodb_table = "carpenter-workshop-terraform-locks"
   }
   ```

3. **Update default values** in `environments/staging/variables.tf`:
   ```hcl
   variable "environment" {
     default = "staging"  # Change default
   }

   # Adjust other defaults as needed (smaller instances, etc.)
   ```

4. **Configure environment-specific values** in `terraform.tfvars`:
   ```hcl
   environment     = "staging"
   vpc_cidr        = "10.1.0.0/16"  # Different CIDR to avoid conflicts
   domain_name     = "staging.carpenterworkshop.net"
   # Use smaller/cheaper instances for staging
   control_plane_instance_type = "t3.micro"
   worker_instance_type        = "t3.micro"
   worker_node_count           = 1
   ```

5. **Deploy the new environment**:
   ```bash
   cd environments/staging
   terraform init
   terraform apply
   ```

## Working with Multiple Environments

Each environment maintains its own:
- **State file**: Isolated in S3 with environment-specific key
- **Resources**: Tagged with environment name
- **Configuration**: Independent variable values

### Switching Between Environments

```bash
# Work on production
cd environments/prod
terraform plan
terraform apply

# Switch to staging
cd ../staging
terraform plan
terraform apply
```

## Module Development

When updating shared modules:

1. **Make changes** in the `modules/` directory
2. **Test changes** in a non-production environment first
3. **Apply to production** after validation

Example module update workflow:

```bash
# Update a module (e.g., modules/vpc/main.tf)
vim modules/vpc/main.tf

# Test in staging first
cd environments/staging
terraform init -upgrade  # Refresh module references
terraform plan
terraform apply

# Apply to production after validation
cd ../prod
terraform init -upgrade
terraform plan
terraform apply
```

## State Management

### Viewing State

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.control_plane

# Pull state locally (for inspection only)
terraform state pull > state.json
```

### State Locking

State is automatically locked during operations using DynamoDB. If a lock gets stuck:

```bash
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

## Best Practices

1. **Always use workspaces or separate directories for environments** ✅ (using separate directories)
2. **Never commit `terraform.tfvars`** - it may contain sensitive values
3. **Use remote state** ✅ (S3 backend configured)
4. **Enable state locking** ✅ (DynamoDB table configured)
5. **Tag all resources** ✅ (automatic tagging configured)
6. **Review plans before applying**
7. **Use version constraints** ✅ (Terraform and provider versions specified)

## Troubleshooting

### Module Not Found

If you see "Module not found" errors:

```bash
terraform init -upgrade
```

### State Lock Errors

If state is locked by a previous operation:

```bash
# Check DynamoDB for the lock
aws dynamodb scan --table-name carpenter-workshop-terraform-locks

# Force unlock if necessary (be careful!)
terraform force-unlock <lock-id>
```

### Backend Initialization Errors

If you see backend initialization errors:

```bash
# Reconfigure backend
terraform init -reconfigure
```

## Cost Estimation

Use the Terraform cost estimation tools:

```bash
# Using Infracost (if installed)
infracost breakdown --path .

# Or manually review the plan
terraform plan -out=plan.tfplan
```

## Security Considerations

1. **State encryption**: Enabled via S3 server-side encryption
2. **State access**: Control via IAM policies
3. **Sensitive outputs**: Marked as sensitive where appropriate
4. **SSH access**: Restrict `allowed_ssh_cidrs` in production
5. **Spot instances**: Use with caution in production (may be interrupted)

## Cleanup

To destroy an environment:

```bash
cd environments/<environment>
terraform destroy
```

To destroy all environments:

```bash
# Destroy each environment
cd environments/staging && terraform destroy
cd ../prod && terraform destroy

# Optionally delete the S3 backend
aws s3 rb s3://carpenter-workshop-terraform-state --force
aws dynamodb delete-table --table-name carpenter-workshop-terraform-locks
```

## Support

For questions or issues:
- Review the [main infrastructure README](../README.md)
- Check environment-specific READMEs in `environments/*/README.md`
- Review module documentation in `modules/*/README.md` (if available)
