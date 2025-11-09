# Route 53 Module Variables

variable "hosted_zone_name" {
  description = "Name of the hosted zone (e.g., carpenterworkshop.net)"
  type        = string
}

variable "hosted_zone_id" {
  description = "ID of existing hosted zone (if empty, will look up by name)"
  type        = string
  default     = ""
}

variable "record_name" {
  description = "DNS record name to create (e.g., carpenterworkshop.net or app.carpenterworkshop.net)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  type        = string
}

variable "create_www_record" {
  description = "Whether to create www subdomain record"
  type        = bool
  default     = false
}
