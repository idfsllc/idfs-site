# AWS Static Site Infrastructure

This Terraform configuration creates a complete AWS infrastructure for hosting a static marketing site with a contact form API. The setup includes:

- **Static Site Hosting**: S3 + CloudFront with Origin Access Control (OAC)
- **SSL/TLS**: ACM certificate with email validation (manual validation required)
- **DNS**: Managed externally (e.g., Squarespace) - Route 53 removed
- **Contact API**: API Gateway HTTP API + Lambda function
- **Email**: Amazon SES for sending contact form emails
- **Security**: Comprehensive security headers and CORS configuration

## Architecture

```
Internet → External DNS (Squarespace) → CloudFront → S3 (Static Site)
                                    ↓
                                 API Gateway → Lambda → SES (Contact Form)
```

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.6 installed
3. **Domain** registered and managed by external DNS provider (e.g., Squarespace)
4. **Email access** for ACM certificate validation

## Required Permissions

Your AWS credentials need the following permissions:
- ACM (certificate management)
- S3 (bucket creation, policy management)
- CloudFront (distribution creation, cache invalidation)
- API Gateway (HTTP API creation)
- Lambda (function creation, IAM roles)
- SES (domain identity, email sending)
- IAM (role and policy creation)

## Quick Start

### 1. Configure Variables

Create a `terraform.tfvars` file or pass variables via command line:

```bash
terraform apply \
  -var 'domain_name=example.com' \
  -var 'to_email=you@example.com' \
  -var 'from_email=noreply@example.com' \
  -var 'recaptcha_site_key=your_site_key' \
  -var 'recaptcha_secret_key=your_secret_key'
```

### 2. Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 3. Verify SES Setup

After deployment, verify your SES configuration:

1. **Domain Identity**: Check AWS SES console for domain verification status
2. **Email Identity**: Verify the FROM email address in SES console
3. **Sandbox Mode**: If SES is in sandbox mode, request production access:
   - Go to AWS SES Console
   - Click "Request production access"
   - Fill out the form with your use case

### 4. Deploy Static Site

```bash
./deploy_static_site.sh
```

This script will:
- Sync your `/site` directory to S3
- Update `contact.html` with the API endpoint
- Invalidate CloudFront cache

### 5. Update Contact Form

After deployment, update `contact.html` with your reCAPTCHA site key:

```javascript
const RECAPTCHA_SITE_KEY = 'your_actual_site_key';
```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `domain_name` | Your domain name (e.g., example.com) | - | Yes |
| `subdomain` | Subdomain for the site | `www` | No |
| `to_email` | Email to receive contact form submissions | - | Yes |
| `from_email` | Email to send from (must be SES-verified) | - | Yes |
| `enable_recaptcha` | Enable reCAPTCHA verification | `true` | No |
| `recaptcha_site_key` | reCAPTCHA site key for frontend | `""` | No |
| `recaptcha_secret_key` | reCAPTCHA secret key for backend | `""` | No |

### Outputs

After deployment, Terraform will output:
- `site_url`: Your site URL (https://www.example.com)
- `cloudfront_domain`: CloudFront distribution domain
- `api_endpoint`: API Gateway endpoint URL
- `ses_identity_status`: SES domain verification status
- `cloudfront_distribution_id`: For cache invalidation
- `s3_bucket_name`: S3 bucket name

## Security Features

### CloudFront Security Headers
- Strict-Transport-Security
- X-Content-Type-Options
- X-Frame-Options
- Referrer-Policy
- Permissions-Policy
- Content-Security-Policy

### CORS Configuration
- Only allows requests from your domain
- Supports POST and OPTIONS methods
- Allows Content-Type header

### IAM Permissions
- Lambda function has minimal permissions
- Can only send emails via SES for your domain
- Can only write to its own CloudWatch log group

## Cost Optimization

This setup is designed to be cost-effective:
- **No EC2 instances** - Serverless architecture
- **No NAT Gateway** - Direct internet access
- **No DynamoDB** - No data persistence
- **CloudFront caching** - Reduces S3 requests
- **Lambda pay-per-request** - Only pay when used

Estimated monthly costs (for low-traffic site):
- CloudFront: ~$1-5
- S3: ~$0.10
- Lambda: ~$0.20
- ACM: Free
- API Gateway: ~$0.35
- SES: ~$0.10
- **Total: ~$2-6/month**

## Testing

### Test the Contact Form

1. Visit your site: `https://www.example.com/contact`
2. Fill out the form and submit
3. Check your email for the submission
4. Check CloudWatch logs for any errors

### Test API Directly

```bash
curl -X POST https://your-api-endpoint/contact \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "message": "Test message"
  }'
```

### Test SSL Certificate

```bash
curl -I https://www.example.com
# Should return 200 OK with security headers
```

## Troubleshooting

### Common Issues

1. **SES Domain Not Verified**
   - Check external DNS provider (e.g., Squarespace) for DNS records
   - Wait for DNS propagation (up to 48 hours)
   - Verify in SES console

2. **Contact Form Not Working**
   - Check API Gateway endpoint in browser console
   - Verify Lambda function logs in CloudWatch
   - Check CORS configuration

3. **SSL Certificate Issues**
   - Ensure ACM certificate is in us-east-1 region
   - Check email validation in ACM console
   - Complete email validation manually

4. **CloudFront Not Updating**
   - Run `./deploy_static_site.sh` to invalidate cache
   - Check CloudFront distribution status
   - Wait 5-15 minutes for cache invalidation

### Logs and Monitoring

- **Lambda Logs**: CloudWatch Logs groups
- **API Gateway Logs**: CloudWatch Logs (if enabled)
- **CloudFront Logs**: S3 bucket (if enabled)
- **SES Bounces**: SES console

## File Structure

```
infra/
├── versions.tf              # Terraform version constraints
├── providers.tf              # AWS provider configuration
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── main.tf                   # Main configuration
├── (route53.tf removed)      # DNS managed externally
├── acm.tf                    # SSL certificate
├── s3_cloudfront.tf          # Static site hosting
├── api_gateway.tf            # HTTP API configuration
├── lambda.tf                 # Lambda functions
├── ses.tf                    # Email service
├── cloudfront_function.js    # Security headers function
├── apex_redirect_function.js # Apex domain redirect
├── contact_options.py        # OPTIONS handler
├── deploy_static_site.sh     # Deployment script
└── README.md                 # This file

lambda/contact/
└── handler.py                # Contact form handler

site/
├── index.html                # Homepage
├── contact.html              # Contact form
└── assets/                   # Static assets
    ├── style.css
    └── script.js
```

## Maintenance

### Updating the Site

1. Modify files in `/site` directory
2. Run `./deploy_static_site.sh`
3. Changes will be live after cache invalidation

### Updating Lambda Function

1. Modify `lambda/contact/handler.py`
2. Run `terraform apply`
3. Lambda function will be updated automatically

### Monitoring Costs

- Use AWS Cost Explorer
- Set up billing alerts
- Monitor CloudWatch metrics

## Support

For issues with this infrastructure:
1. Check AWS service status
2. Review CloudWatch logs
3. Verify Terraform state
4. Check DNS propagation

## License

This infrastructure code is provided as-is for educational and production use.
