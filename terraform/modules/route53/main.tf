# Route 53 DNS Configuration

# Data source to fetch existing hosted zone
data "aws_route53_zone" "main" {
  count = var.hosted_zone_id == "" ? 1 : 0
  name  = var.hosted_zone_name
}

locals {
  zone_id = var.hosted_zone_id != "" ? var.hosted_zone_id : data.aws_route53_zone.main[0].zone_id
}

# A Record (Alias) pointing to ALB for the application subdomain
resource "aws_route53_record" "main" {
  zone_id = local.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
