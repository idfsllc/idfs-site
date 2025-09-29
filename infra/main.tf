# Main Terraform configuration file
# This file wires together all the modules and resources

# Data source to get the Route 53 zone
# COMMENTED OUT FOR TESTING WITHOUT DOMAIN
# data "aws_route53_zone" "main" {
#   name         = var.domain_name
#   private_zone = false
# }

# Local values for common configurations
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = "static-site"
    Environment = "production"
    ManagedBy   = "terraform"
  }
  
  # Domain configurations
  apex_domain = var.domain_name
  www_domain  = "${var.subdomain}.${var.domain_name}"
  
  # Lambda environment variables
  lambda_env_vars = {
    TO_EMAIL         = var.to_email
    FROM_EMAIL       = var.from_email
    ENABLE_RECAPTCHA = var.enable_recaptcha
    RECAPTCHA_SECRET = var.recaptcha_secret_key
    # ALLOWED_ORIGIN   = "https://${local.www_domain}"  # Commented out for testing
    ALLOWED_ORIGIN   = "*"  # Allow all origins for testing (will be CloudFront domain)
  }
}
