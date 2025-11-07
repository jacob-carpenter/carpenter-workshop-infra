# Compute Module Variables

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for K8s control plane"
  type        = string
}

variable "worker_instance_type" {
  description = "EC2 instance type for K8s worker nodes"
  type        = string
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "use_spot_instances" {
  description = "Use EC2 spot instances for cost savings"
  type        = bool
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (empty for on-demand price)"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of existing SSH key pair for EC2 access"
  type        = string
  default     = ""
}

variable "control_plane_sg_id" {
  description = "Security group ID for control plane"
  type        = string
}

variable "worker_sg_id" {
  description = "Security group ID for worker nodes"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
