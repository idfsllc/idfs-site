output "site_url" {
  description = "The URL of the static site (CloudFront domain for testing)"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "cloudfront_domain" {
  description = "The CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "ses_identity_status" {
  description = "The SES email identity (check AWS SES console for verification status)"
  value       = aws_ses_email_identity.from_email.email
}

output "cloudfront_distribution_id" {
  description = "The CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket_name" {
  description = "The S3 bucket name for static site hosting"
  value       = aws_s3_bucket.site.bucket
}
