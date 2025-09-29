#!/bin/bash

# IDFS Website - Quick Setup Script
# This script helps set up the environment for deployment

set -e

echo "🚀 IDFS Website - Environment Setup"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "infra/main.tf" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    echo "   (where you can see the 'infra' folder)"
    exit 1
fi

echo "✅ Found project files"

# Check for required tools
echo ""
echo "🔍 Checking prerequisites..."

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n1)
    echo "✅ Terraform found: $TERRAFORM_VERSION"
else
    echo "❌ Terraform not found"
    echo "   Install from: https://terraform.io/downloads"
    exit 1
fi

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    echo "✅ AWS CLI found: $AWS_VERSION"
else
    echo "❌ AWS CLI not found"
    echo "   Install from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    echo "✅ AWS credentials configured"
    echo "   Account: $AWS_ACCOUNT"
    echo "   User: $AWS_USER"
else
    echo "❌ AWS credentials not configured"
    echo "   Run: aws configure"
    exit 1
fi

# Check if terraform.tfvars exists
echo ""
echo "📝 Checking configuration..."

if [ -f "infra/terraform.tfvars" ]; then
    echo "✅ terraform.tfvars found"
else
    echo "⚠️  terraform.tfvars not found"
    echo "   Creating template..."
    
    cat > infra/terraform.tfvars << EOF
# IDFS Website Configuration
# Update these values for your deployment

# Domain Configuration (optional for testing)
domain_name = "yourdomain.com"
subdomain   = "www"

# Email Configuration
to_email   = "your-email@example.com"
from_email = "noreply@yourdomain.com"

# Optional: reCAPTCHA (if you want spam protection)
enable_recaptcha = false
recaptcha_secret_key = ""
EOF
    
    echo "✅ Created terraform.tfvars template"
    echo "   Please edit infra/terraform.tfvars with your values"
fi

# Check if .terraform directory exists
echo ""
echo "🔧 Checking Terraform initialization..."

if [ -d "infra/.terraform" ]; then
    echo "✅ Terraform initialized"
else
    echo "⚠️  Terraform not initialized"
    echo "   Run: cd infra && terraform init"
fi

# Summary
echo ""
echo "📋 Setup Summary:"
echo "================="
echo "✅ Project structure: OK"
echo "✅ Terraform: $(command -v terraform &> /dev/null && echo "OK" || echo "MISSING")"
echo "✅ AWS CLI: $(command -v aws &> /dev/null && echo "OK" || echo "MISSING")"
echo "✅ AWS Credentials: $(aws sts get-caller-identity &> /dev/null && echo "OK" || echo "MISSING")"
echo "✅ Configuration: $([ -f "infra/terraform.tfvars" ] && echo "OK" || echo "NEEDS SETUP")"
echo "✅ Terraform Init: $([ -d "infra/.terraform" ] && echo "OK" || echo "NEEDS RUN")"

echo ""
echo "🚀 Next Steps:"
echo "=============="
echo "1. Edit infra/terraform.tfvars with your values"
echo "2. cd infra && terraform init"
echo "3. terraform plan"
echo "4. terraform apply"
echo "5. ../infra/deploy_static_site.sh"

echo ""
echo "📚 For detailed instructions, see DEPLOYMENT_GUIDE.md"
echo "💰 For cost control info, see infra/COST_CONTROL_README.md"

echo ""
echo "✅ Setup check complete!"
