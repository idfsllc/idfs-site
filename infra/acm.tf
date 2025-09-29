# ACM SSL Certificate configuration
# Creates DNS-validated certificate for domain and wildcard subdomain
# COMMENTED OUT FOR TESTING WITHOUT DOMAIN

# # SSL certificate for the domain and wildcard subdomain
# resource "aws_acm_certificate" "site" {
#   domain_name               = local.apex_domain
#   subject_alternative_names = ["*.${local.apex_domain}"]
#   validation_method         = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = local.common_tags
# }

# # DNS validation record for the main domain
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }

# # Wait for certificate validation
# resource "aws_acm_certificate_validation" "site" {
#   certificate_arn         = aws_acm_certificate.site.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }
