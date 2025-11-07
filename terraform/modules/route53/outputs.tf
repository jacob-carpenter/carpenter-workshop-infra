# Route 53 Module Outputs

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = local.zone_id
}

output "record_name" {
  description = "DNS record name created"
  value       = aws_route53_record.main.name
}

output "record_fqdn" {
  description = "Fully qualified domain name"
  value       = aws_route53_record.main.fqdn
}

output "www_record_fqdn" {
  description = "WWW subdomain FQDN (if created)"
  value       = var.create_www_record ? aws_route53_record.www[0].fqdn : ""
}
