#!/bin/bash

# IDFS AWS Deployment Script
# This script ensures only the website files go to AWS, not local development files

set -e

echo "🚀 Starting AWS deployment for IDFS website..."

# Check if we're in the right directory
if [ ! -f "index.html" ]; then
    echo "❌ Error: index.html not found. Are you in the project root?"
    exit 1
fi

# Check if infra directory exists
if [ ! -d "infra" ]; then
    echo "❌ Error: infra directory not found. Run this from the project root."
    exit 1
fi

# Create a temporary directory for AWS deployment files
TEMP_DIR=$(mktemp -d)
echo "📁 Created temporary directory: $TEMP_DIR"

# Copy only the website files (exclude local dev files)
echo "📋 Copying website files to deployment directory..."
cp index.html "$TEMP_DIR/"
cp contact.html "$TEMP_DIR/"
cp capabilities.html "$TEMP_DIR/"
cp certifications.html "$TEMP_DIR/"
cp industries.html "$TEMP_DIR/"
cp styles.css "$TEMP_DIR/"
cp script.js "$TEMP_DIR/"
cp robots.txt "$TEMP_DIR/"
cp sitemap.xml "$TEMP_DIR/"

# Copy assets directory
if [ -d "assets" ]; then
    cp -r assets "$TEMP_DIR/"
fi

# Update script.js to use AWS API endpoint (not local)
echo "🔧 Updating script.js for AWS deployment..."
sed -i.bak 's|fetch('\''/contact'\'')|fetch('\''https://c032c9t2fl.execute-api.us-east-1.amazonaws.com/prod/contact'\'')|g' "$TEMP_DIR/script.js"
rm "$TEMP_DIR/script.js.bak"

echo "✅ Files ready for AWS deployment:"
ls -la "$TEMP_DIR"

# Deploy to AWS
echo "☁️ Deploying to AWS..."
cd infra

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Apply Terraform (create/update infrastructure)
echo "🏗️ Applying Terraform configuration..."
terraform apply -auto-approve

# Get outputs
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

if [ -z "$S3_BUCKET" ]; then
    echo "❌ Error: Could not get S3 bucket name from Terraform"
    exit 1
fi

# Sync files to S3
echo "📤 Syncing files to S3 bucket: $S3_BUCKET"
aws s3 sync "$TEMP_DIR" "s3://$S3_BUCKET" --delete

# Invalidate CloudFront cache
if [ ! -z "$CLOUDFRONT_ID" ]; then
    echo "🔄 Invalidating CloudFront cache..."
    INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_ID" --paths "/*" --query 'Invalidation.Id' --output text)
    echo "✅ CloudFront invalidation created: $INVALIDATION_ID"
fi

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 Deployment completed successfully!"
echo "🌐 Your site should be available at: https://$(terraform output -raw cloudfront_domain)"
echo ""
echo "📝 Note: Local development files (package.json, server.js, node_modules) were NOT deployed to AWS"
