# ACM SSL Certificate configuration
# Creates DNS-validated certificate for domain and wildcard subdomain

# SSL certificate for the domain and wildcard subdomain
# Note: Certificate validation will be done manually via email
resource "aws_acm_certificate" "site" {
  domain_name               = "idfsllc.com"
  subject_alternative_names = ["*.idfsllc.com"]
  validation_method         = "EMAIL"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# Note: Certificate validation must be done manually via email
# Check AWS ACM console for validation emails
# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn = aws_acm_certificate.site.arn
#   timeouts {
#     create = "10m"
#   }
# }