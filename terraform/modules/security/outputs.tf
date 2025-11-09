# Security Module Outputs

output "control_plane_security_group_id" {
  description = "ID of control plane security group"
  value       = aws_security_group.control_plane.id
}

output "worker_security_group_id" {
  description = "ID of worker security group"
  value       = aws_security_group.worker_nodes.id
}

output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb.id
}
