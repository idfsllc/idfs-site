# S3 and CloudFront configuration for static site hosting
# Private S3 bucket with CloudFront OAC for secure content delivery

# S3 bucket for static site hosting
resource "aws_s3_bucket" "site" {
  bucket = "static-site-${random_id.bucket_suffix.hex}"

  tags = local.common_tags
}

# Random ID for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "static-site-oac"
  description                       = "OAC for static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Function for security headers
resource "aws_cloudfront_function" "security_headers" {
  name    = "static-site-security-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Add security headers to responses"
  publish = true
  code    = file("${path.module}/cloudfront_function.js")
}

# CloudFront Function for apex domain redirect
# COMMENTED OUT FOR TESTING WITHOUT DOMAIN
# resource "aws_cloudfront_function" "apex_redirect" {
#   name    = "${local.www_domain}-apex-redirect"
#   runtime = "cloudfront-js-1.0"
#   comment = "Redirect apex domain to www subdomain"
#   publish = true
#   code    = templatefile("${path.module}/apex_redirect_function.js", {
#     apex_domain = local.apex_domain
#     www_domain  = local.www_domain
#   })
# }

# CloudFront cache policy
resource "aws_cloudfront_cache_policy" "site" {
  name        = "static-site-cache-policy"
  comment     = "Cache policy for static site"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip  = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# CloudFront origin request policy
resource "aws_cloudfront_origin_request_policy" "site" {
  name    = "static-site-origin-request-policy"
  comment = "Origin request policy for static site"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

# CloudFront response headers policy
resource "aws_cloudfront_response_headers_policy" "site" {
  name    = "static-site-response-headers-policy"
  comment = "Response headers policy for static site"

  security_headers_config {
    content_type_options {
      override = false
    }
    frame_options {
      frame_option = "DENY"
      override     = false
    }
    referrer_policy {
      referrer_policy = "no-referrer-when-downgrade"
      override        = false
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = false
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "geolocation=(), microphone=(), camera=()"
      override = false
    }
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "site" {
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
    origin_id                = "S3-${aws_s3_bucket.site.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  aliases = ["idfsllc.com", "www.idfsllc.com"]

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods        = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.site.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = aws_cloudfront_cache_policy.site.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.site.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }

    # function_association {
    #   event_type   = "viewer-request"
    #   function_arn = aws_cloudfront_function.apex_redirect.arn
    # }
  }

  # Custom error pages
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.common_tags
}

# S3 bucket policy to allow CloudFront OAC access
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.site]
}
