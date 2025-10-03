# DNS Setup Guide for Squarespace

This guide explains how to configure your domain DNS in Squarespace to work with your CloudFront distribution.

## Prerequisites

- CloudFront distribution deployed via Terraform
- ACM certificate validated (check AWS ACM console)
- Domain registered with Squarespace

## DNS Records to Add in Squarespace

### 1. Apex Domain (idfsllc.com)

Add a **CNAME** record:
- **Name**: `@` (or leave blank for apex domain)
- **Value**: Your CloudFront domain (e.g., `d1234567890.cloudfront.net`)
- **TTL**: 3600 (1 hour)

**Note**: Some DNS providers don't allow CNAME records for the apex domain. If Squarespace doesn't support this, you may need to use an A record pointing to CloudFront's IP addresses.

### 2. WWW Subdomain (www.idfsllc.com)

Add a **CNAME** record:
- **Name**: `www`
- **Value**: Your CloudFront domain (e.g., `d1234567890.cloudfront.net`)
- **TTL**: 3600 (1 hour)

## Finding Your CloudFront Domain

After running `terraform apply`, you can find your CloudFront domain in the outputs:

```bash
terraform output cloudfront_domain
```

Or check the Terraform outputs:
```bash
terraform output
```

## Verification

1. **Wait for DNS propagation** (up to 48 hours)
2. **Test your domain**:
   - Visit `https://idfsllc.com` - should redirect to CloudFront
   - Visit `https://www.idfsllc.com` - should load your site
3. **Check SSL certificate** - should show as valid
4. **Test contact form** - should work with your domain

## Troubleshooting

### SSL Certificate Issues
- Ensure ACM certificate is validated in AWS console
- Check that certificate covers both `idfsllc.com` and `*.idfsllc.com`
- Verify certificate is in `us-east-1` region

### DNS Not Working
- Check DNS propagation: https://www.whatsmydns.net/
- Verify CNAME records are correct
- Wait up to 48 hours for full propagation

### CloudFront Not Updating
- Run cache invalidation: `./deploy_static_site.sh`
- Check CloudFront distribution status in AWS console

## Cost Savings

By removing Route 53 and using Squarespace DNS:
- **Route 53 hosted zone**: $0.50/month (saved)
- **Route 53 queries**: $0.40 per million queries (saved)
- **Total savings**: ~$0.50-1.00/month

Your total AWS costs are now reduced to:
- CloudFront: ~$1-5/month
- S3: ~$0.10/month
- Lambda: ~$0.20/month
- ACM: Free
- API Gateway: ~$0.35/month
- SES: ~$0.10/month
- **Total: ~$2-6/month**
