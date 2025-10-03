# Testing Guide - No Domain Required

This guide shows how to test the infrastructure without owning a domain name.

## What's Different for Testing

- ✅ **CloudFront works perfectly** - You'll access via CloudFront domain (e.g., `d1234567890.cloudfront.net`)
- ✅ **SSL works** - CloudFront provides a default SSL certificate
- ✅ **Contact form works** - API Gateway + Lambda + SES (with verified email)
- ❌ **No custom domain** - ACM and domain-specific SES features require manual setup
- ❌ **No apex redirect** - CloudFront function for redirect is commented out

## Quick Start

### 1. Deploy Infrastructure

```bash
cd infra
terraform init
terraform apply \
  -var 'domain_name=test.example.com' \
  -var 'to_email=your-email@gmail.com' \
  -var 'from_email=your-email@gmail.com'
```

**Note**: Use any fake domain name for `domain_name` - it won't be used for DNS.

### 2. Verify SES Email

After deployment, you need to verify your FROM email in AWS SES:

1. Go to AWS SES Console
2. Click "Verified identities" 
3. Find your email address
4. Click "Verify" if not already verified
5. Check your email and click the verification link

### 3. Deploy Static Site

```bash
./deploy_static_site.sh
```

### 4. Test Your Site

1. Get your CloudFront URL:
   ```bash
   terraform output site_url
   ```

2. Visit the URL in your browser (e.g., `https://d1234567890.cloudfront.net`)

3. Test the contact form at `/contact.html`

### 5. Update reCAPTCHA (Optional)

If you want to test reCAPTCHA:

1. Get reCAPTCHA keys from [Google reCAPTCHA](https://www.google.com/recaptcha/)
2. Update `contact.html`:
   ```javascript
   const RECAPTCHA_SITE_KEY = 'your_actual_site_key';
   ```
3. Redeploy:
   ```bash
   ./deploy_static_site.sh
   ```

## Testing the Contact Form

### Via Browser
1. Go to `https://your-cloudfront-domain.cloudfront.net/contact.html`
2. Fill out the form and submit
3. Check your email for the submission

### Via API (curl)
```bash
# Get API endpoint
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Test the API
curl -X POST $API_ENDPOINT/contact \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com", 
    "message": "This is a test message"
  }'
```

## What You'll See

### CloudFront Domain
- Your site will be accessible via a CloudFront domain like:
  - `https://d1234567890.cloudfront.net`
  - `https://d1234567890.cloudfront.net/contact.html`

### SSL Certificate
- CloudFront provides a default SSL certificate
- Your site will show as secure (green lock icon)
- Certificate will be for `*.cloudfront.net`

### Contact Form
- Form will work and send emails via SES
- You'll receive emails at your `to_email` address
- No data is stored anywhere (as requested)

## Troubleshooting

### SES Email Not Verified
```bash
# Check SES verification status
terraform output ses_identity_status
```

If not verified:
1. Go to AWS SES Console
2. Verify your email address
3. Check spam folder for verification email

### Contact Form Not Working
1. Check CloudWatch logs for Lambda function
2. Verify API Gateway endpoint is correct
3. Check browser console for JavaScript errors

### CloudFront Not Updating
```bash
# Force cache invalidation
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## Cost for Testing

Estimated monthly costs for testing:
- CloudFront: ~$1-2
- S3: ~$0.10
- Lambda: ~$0.20
- API Gateway: ~$0.35
- SES: ~$0.10
- **Total: ~$1.75/month**

## Next Steps

When you're ready to use a real domain:

1. **Set up ACM certificate** - Certificate will be created with email validation
2. **Complete email validation** - Check AWS ACM console for validation emails
3. **Update CloudFront aliases** in `s3_cloudfront.tf` (already configured)
4. **Set up DNS records** in your external DNS provider (e.g., Squarespace)
5. **Update CORS origins** to your domain
6. **Run `terraform apply`** with your real domain

## Clean Up

To avoid charges, destroy the infrastructure:

```bash
terraform destroy
```

This will remove all AWS resources created by Terraform.
