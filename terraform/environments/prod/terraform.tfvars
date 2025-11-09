# AWS Configuration
aws_region   = "us-east-1"
environment  = "prod"
project_name = "carpenter-workshop"

# Networking
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# Instance Configuration
control_plane_instance_type = "t3.small" # 2 vCPU, 2GB RAM
worker_instance_type        = "t3.small" # 2 vCPU, 2GB RAM
worker_node_count           = 2

# Cost Optimization - Use spot instances for ~70% savings
use_spot_instances = true
spot_max_price     = ""

# SSH Access
ssh_key_name      = "carpenter-workshop-key"
allowed_ssh_cidrs = ["136.32.57.168/32"]
allowed_api_cidrs = ["136.32.57.168/32"]

# Application Configuration
domain_name = "carpenterworkshop.net"

# SSL Certificate
certificate_arn = ""

# Tags
tags = {
  Owner      = "Jacob Carpenter"
  CostCenter = "Personal"
  Terraform  = "true"
}
