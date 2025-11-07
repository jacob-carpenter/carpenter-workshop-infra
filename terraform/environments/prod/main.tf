# Production Environment Configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "carpenter-workshop-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "carpenter-workshop-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "K8s-Cluster"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  tags                = var.tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  allowed_api_cidrs = var.allowed_api_cidrs
  tags              = var.tags
}

# Compute Module (K8s Cluster)
module "compute" {
  source = "../../modules/compute"

  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = module.vpc.vpc_id
  public_subnets              = module.vpc.public_subnet_ids
  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type
  worker_node_count           = var.worker_node_count
  use_spot_instances          = var.use_spot_instances
  spot_max_price              = var.spot_max_price
  ssh_key_name                = var.ssh_key_name
  control_plane_sg_id         = module.security.control_plane_security_group_id
  worker_sg_id                = module.security.worker_security_group_id
  alb_target_group_arn        = ""
  tags                        = var.tags
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name         = var.project_name
  environment          = var.environment
  repository_name      = "carpenter-workshop"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 10
  untagged_image_days  = 7
  tags                 = var.tags
}

# ACM Certificate Module
module "acm" {
  source = "../../modules/acm"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name

  # Include www subdomain
  subject_alternative_names = ["www.${var.domain_name}"]

  tags = var.tags
}

