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

# # Route 53 record for SES domain verification
# resource "aws_route53_record" "ses_verification" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "_amazonses.${aws_ses_domain_identity.domain.domain}"
#   type    = "TXT"
#   ttl     = 600
#   records = [aws_ses_domain_identity.domain.verification_token]
# }

# # Route 53 records for DKIM verification
# resource "aws_route53_record" "ses_dkim" {
#   count   = 3
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "${aws_ses_domain_dkim.domain.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.domain.domain}"
#   type    = "CNAME"
#   ttl     = 600
#   records = ["${aws_ses_domain_dkim.domain.dkim_tokens[count.index]}.dkim.amazonses.com"]
# }

# SES email identity for FROM address (this can work without domain)
resource "aws_ses_email_identity" "from_email" {
  email = var.from_email
}

# # Route 53 MX record for domain (optional, for receiving emails)
# resource "aws_route53_record" "ses_mx" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = local.apex_domain
#   type    = "MX"
#   ttl     = 600
#   records = ["10 inbound-smtp.us-east-1.amazonaws.com"]
# }
