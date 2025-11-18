# SES configuration for email sending
# Sets up domain identity, DKIM, and email verification
# COMMENTED OUT FOR TESTING WITHOUT DOMAIN

# # SES domain identity
# resource "aws_ses_domain_identity" "domain" {
#   domain = local.apex_domain

#   tags = local.common_tags
# }

# # SES domain DKIM
# resource "aws_ses_domain_dkim" "domain" {
#   domain = aws_ses_domain_identity.domain.domain
# }

# SES email identity for FROM address (this can work without domain)
resource "aws_ses_email_identity" "from_email" {
  email = var.from_email
}
