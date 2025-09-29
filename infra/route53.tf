# Route 53 DNS configuration
# Handles DNS records for the domain and subdomain
# COMMENTED OUT FOR TESTING WITHOUT DOMAIN

# # A record for www subdomain pointing to CloudFront
# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = local.www_domain
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.site.domain_name
#     zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# # AAAA record for www subdomain pointing to CloudFront (IPv6)
# resource "aws_route53_record" "www_ipv6" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = local.www_domain
#   type    = "AAAA"

#   alias {
#     name                   = aws_cloudfront_distribution.site.domain_name
#     zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# # Apex domain redirect to www subdomain
# # Using CloudFront function for redirect (simpler than separate S3+CF setup)
# resource "aws_route53_record" "apex" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = local.apex_domain
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.site.domain_name
#     zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# # AAAA record for apex domain (IPv6)
# resource "aws_route53_record" "apex_ipv6" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = local.apex_domain
#   type    = "AAAA"

#   alias {
#     name                   = aws_cloudfront_distribution.site.domain_name
#     zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
