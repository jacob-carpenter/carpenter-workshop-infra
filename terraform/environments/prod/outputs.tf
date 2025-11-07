# Outputs for Production Environment

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

# ALB Outputs - Disabled (now managed by AWS Load Balancer Controller)
# To get ALB DNS after deployment:
# kubectl get ingress -n carpenter-workshop carpenter-workshop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# output "alb_dns_name" {
#   description = "DNS name of the Application Load Balancer"
#   value       = module.alb.alb_dns_name
# }
#
# output "alb_zone_id" {
#   description = "Zone ID of the Application Load Balancer"
#   value       = module.alb.alb_zone_id
# }
#
# output "target_group_arn" {
#   description = "ARN of the target group"
#   value       = module.alb.target_group_arn
# }

# Compute Outputs
output "control_plane_public_ip" {
  description = "Public IP of the control plane"
  value       = module.compute.control_plane_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane"
  value       = module.compute.control_plane_private_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = module.compute.worker_public_ips
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = module.compute.worker_private_ips
}

# Security Group Outputs
output "control_plane_security_group_id" {
  description = "ID of control plane security group"
  value       = module.security.control_plane_security_group_id
}

output "worker_security_group_id" {
  description = "ID of worker security group"
  value       = module.security.worker_security_group_id
}

output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = module.security.alb_security_group_id
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository for carpenter-workshop"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = module.ecr.registry_id
}

# ACM Certificate Outputs
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  value       = module.acm.certificate_arn
}

output "acm_certificate_domain" {
  description = "Domain name for the certificate"
  value       = module.acm.certificate_domain_name
}

output "acm_certificate_status" {
  description = "Validation status of the certificate"
  value       = module.acm.certificate_status
}

# Instructions
output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    Deployment complete! Next steps:

    1. Wait 5-10 minutes for K3s installation to complete

    2. Get kubeconfig:
       aws ssm get-parameter \
         --name /${var.project_name}-${var.environment}-kubeconfig \
         --with-decryption \
         --query 'Parameter.Value' \
         --output text \
         --region ${var.aws_region} > ~/kubeconfig

    3. Update kubeconfig server URL:
       export CONTROL_PLANE_IP=${module.compute.control_plane_public_ip}
       sed -i "s|127.0.0.1|$CONTROL_PLANE_IP|g" ~/kubeconfig

    4. Set KUBECONFIG:
       export KUBECONFIG=~/kubeconfig

    5. Verify cluster:
       kubectl get nodes

    6. Deploy cluster baseline (includes AWS Load Balancer Controller):
       cd ../../../kubernetes/cluster-baseline
       helm dependency update .
       helm install cluster-baseline ./ --namespace cluster-baseline --values values.yaml --create-namespace

    7. Update any relevant interacting app to use latest HMAC secure token:
       aws ssm get-parameter \
         --name "carpenter-workshop-${var.environment}-hmac-token" \
         --with-decryption \
         --query 'Parameter.Value' \
         --output text \
         --region ${var.aws_region}

    8. Update any relevant Kubernetes app to use ACM certificate:
       Certificate ARN: ${module.acm.certificate_arn}

       Update the ingress annotation in your app's values.yaml:
       alb.ingress.kubernetes.io/certificate-arn: ${module.acm.certificate_arn}
  EOT
}
