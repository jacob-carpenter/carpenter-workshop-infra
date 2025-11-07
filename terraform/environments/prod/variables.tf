# Variables for Production Environment

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "carpenter-workshop"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# EC2 Instance Configuration
variable "control_plane_instance_type" {
  description = "EC2 instance type for K8s control plane"
  type        = string
  default     = "t3.small" # 2 vCPU, 2GB RAM
}

variable "worker_instance_type" {
  description = "EC2 instance type for K8s worker nodes"
  type        = string
  default     = "t3.small" # 2 vCPU, 2GB RAM
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "use_spot_instances" {
  description = "Use EC2 spot instances for cost savings"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (empty for on-demand price)"
  type        = string
  default     = "" # Let AWS determine the spot price
}

# Application Configuration
variable "domain_name" {
  description = "Domain name for the application (can be root domain or subdomain)"
  type        = string
  default     = "carpenterworkshop.net"
}

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name (e.g., carpenterworkshop.net)"
  type        = string
  default     = "carpenterworkshop.net"
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID (if empty, will look up by name)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}

# SSH Key
variable "ssh_key_name" {
  description = "Name of existing SSH key pair for EC2 access"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = []
}

variable "allowed_api_cidrs" {
  description = "CIDR blocks allowed to access K3s API server (port 6443)"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
