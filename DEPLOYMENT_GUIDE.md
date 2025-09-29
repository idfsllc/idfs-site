# IDFS Website - Environment Setup Guide

## 🚀 **What You Need to Deploy on Another Environment**

### **Prerequisites:**
1. **AWS Account** with billing enabled
2. **Terraform** installed (version >= 1.0)
3. **AWS CLI** configured with credentials
4. **Domain name** (optional - can test without)

---

## 📋 **Step-by-Step Setup**

### **1. Clone the Repository**
```bash
git clone <your-repo-url>
cd idfs
```

### **2. Install Prerequisites**

#### **Install Terraform:**
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows
# Download from https://terraform.io/downloads
```

#### **Install AWS CLI:**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download from https://aws.amazon.com/cli/
```

### **3. Configure AWS Credentials**
```bash
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (us-east-1)
# - Default output format (json)
```

### **4. Set Up Terraform Variables**

Create `infra/terraform.tfvars`:
```hcl
# Domain Configuration (optional for testing)
domain_name = "yourdomain.com"
subdomain   = "www"

# Email Configuration
to_email   = "your-email@example.com"
from_email = "noreply@yourdomain.com"

# Optional: reCAPTCHA (if you want spam protection)
enable_recaptcha = false
recaptcha_secret_key = ""
```

### **5. Deploy Infrastructure**
```bash
cd infra
terraform init
terraform plan
terraform apply
```

### **6. Deploy Website Content**
```bash
# From project root
./infra/deploy_static_site.sh
```

---

## 🔧 **Required Files & Dependencies**

### **Core Files (Already in Repo):**
- ✅ `infra/` - All Terraform configuration
- ✅ `site/` - Website HTML/CSS/JS
- ✅ `lambda/` - Contact form Lambda function
- ✅ `.gitignore` - Git ignore rules

### **Files You Need to Create:**
- 📝 `infra/terraform.tfvars` - Your specific variables
- 📝 AWS credentials (via `aws configure`)

### **Files Generated During Deployment:**
- 🔄 `infra/.terraform/` - Terraform provider downloads
- 🔄 `infra/*.tfstate` - Terraform state files
- 🔄 `infra/*.zip` - Lambda deployment packages

---

## 🌐 **Domain Setup (Optional)**

### **Without Domain (Testing):**
- Uses CloudFront default certificate
- Access via CloudFront URL
- No DNS configuration needed

### **With Domain (Production):**
1. **Uncomment domain resources** in `infra/main.tf`:
   ```hcl
   # Uncomment these lines:
   data "aws_route53_zone" "main" {
     name         = var.domain_name
     private_zone = false
   }
   ```

2. **Uncomment Route 53** in `infra/route53.tf`

3. **Uncomment ACM** in `infra/acm.tf`

4. **Update CloudFront** in `infra/s3_cloudfront.tf`:
   ```hcl
   # Uncomment aliases and certificate
   aliases = [local.www_domain]
   
   viewer_certificate {
     acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
     ssl_support_method       = "sni-only"
     minimum_protocol_version = "TLSv1.2_2021"
   }
   ```

---

## 💰 **Cost Control Setup**

### **Automatic Cost Protection:**
- ✅ **$10/month** - Alert emails
- ✅ **$20/month** - Contact form disabled (website stays up)
- ✅ **Daily monitoring** - Automatic cost checks

### **Email Notifications:**
Make sure `to_email` in `terraform.tfvars` is correct - this is where cost alerts go.

---

## 🔍 **Verification Steps**

### **1. Check Infrastructure:**
```bash
terraform output
# Should show:
# - site_url (CloudFront URL)
# - api_endpoint (API Gateway URL)
# - ses_identity_status
```

### **2. Test Website:**
- Visit CloudFront URL
- Check all pages load
- Test contact form

### **3. Test Contact Form:**
- Submit a test message
- Check email delivery
- Verify Lambda logs

---

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **"Access Denied" on CloudFront:**
```bash
# Run deployment script
./infra/deploy_static_site.sh
```

#### **Contact Form Not Working:**
```bash
# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/static-site"
```

#### **SES Email Not Verified:**
```bash
# Check SES console
aws ses get-identity-verification-attributes --identities your-email@example.com
```

#### **Terraform State Issues:**
```bash
# Re-initialize
terraform init -upgrade
```

---

## 📊 **Expected Costs**

### **Monthly AWS Costs:**
- **S3 Storage**: ~$0.50-1.00
- **CloudFront**: ~$1.00-3.00
- **Lambda**: ~$0.50-2.00
- **API Gateway**: ~$0.50-1.00
- **SES**: ~$0.10-0.50
- **Route 53**: ~$0.50 (if using domain)
- **Total**: **$3-8/month**

---

## 🔐 **Security Notes**

### **What's Protected:**
- ✅ **Terraform state** - Contains sensitive data (in .gitignore)
- ✅ **AWS credentials** - Not in repository
- ✅ **Email addresses** - In terraform.tfvars (not committed)
- ✅ **Domain secrets** - In terraform.tfvars

### **What's Public:**
- ✅ **Website content** - HTML/CSS/JS
- ✅ **Infrastructure code** - Terraform files
- ✅ **Lambda code** - Contact form function

---

## 📝 **Quick Start Checklist**

- [ ] AWS account with billing enabled
- [ ] Terraform installed
- [ ] AWS CLI configured
- [ ] Repository cloned
- [ ] `infra/terraform.tfvars` created
- [ ] `terraform init` run
- [ ] `terraform apply` run
- [ ] `./infra/deploy_static_site.sh` run
- [ ] Website tested
- [ ] Contact form tested

**You're ready to deploy!** 🚀
