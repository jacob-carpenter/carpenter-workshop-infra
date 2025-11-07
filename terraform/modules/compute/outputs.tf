# Compute Module Outputs

output "control_plane_id" {
  description = "ID of control plane instance"
  value       = aws_instance.control_plane.id
}

output "control_plane_public_ip" {
  description = "Public IP of control plane (Elastic IP - permanent)"
  value       = aws_eip.control_plane.public_ip
}

output "control_plane_eip_allocation_id" {
  description = "Allocation ID of control plane Elastic IP"
  value       = aws_eip.control_plane.id
}

output "control_plane_private_ip" {
  description = "Private IP of control plane"
  value       = aws_instance.control_plane.private_ip
}

output "worker_ids" {
  description = "IDs of worker instances"
  value       = aws_instance.worker_nodes[*].id
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = aws_instance.worker_nodes[*].public_ip
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = aws_instance.worker_nodes[*].private_ip
}

output "control_plane_role_arn" {
  description = "ARN of control plane IAM role"
  value       = aws_iam_role.control_plane.arn
}

output "worker_role_arn" {
  description = "ARN of worker nodes IAM role"
  value       = aws_iam_role.worker_nodes.arn
}
