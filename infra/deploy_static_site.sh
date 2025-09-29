#!/bin/bash

# Deploy static site to S3 and invalidate CloudFront cache
# This script syncs the /site directory to S3 and invalidates CloudFront cache

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    print_status "All dependencies are installed."
}

# Get Terraform outputs
get_terraform_outputs() {
    print_status "Getting Terraform outputs..."
    
    if [ ! -f "terraform.tfstate" ]; then
        print_error "terraform.tfstate not found. Please run 'terraform apply' first."
        exit 1
    fi
    
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    
    if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        print_error "Failed to get Terraform outputs. Please check your Terraform state."
        exit 1
    fi
    
    print_status "S3 Bucket: $S3_BUCKET"
    print_status "CloudFront Distribution ID: $CLOUDFRONT_DISTRIBUTION_ID"
}

# Sync files to S3
sync_to_s3() {
    print_status "Syncing files to S3..."
    
    # Get the site directory path (parent directory of this script)
    SITE_DIR="$(dirname "$(dirname "$(realpath "$0")")")/site"
    
    if [ ! -d "$SITE_DIR" ]; then
        print_error "Site directory not found: $SITE_DIR"
        exit 1
    fi
    
    print_status "Syncing from: $SITE_DIR"
    
    # Sync files to S3 with appropriate content types
    aws s3 sync "$SITE_DIR" "s3://$S3_BUCKET" \
        --delete \
        --cache-control "public, max-age=31536000" \
        --exclude "*.html" \
        --exclude "*.css" \
        --exclude "*.js"
    
    # Sync HTML files with shorter cache
    aws s3 sync "$SITE_DIR" "s3://$S3_BUCKET" \
        --cache-control "public, max-age=3600" \
        --include "*.html"
    
    # Sync CSS and JS files with medium cache
    aws s3 sync "$SITE_DIR" "s3://$S3_BUCKET" \
        --cache-control "public, max-age=86400" \
        --include "*.css" \
        --include "*.js"
    
    print_status "Files synced to S3 successfully."
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    print_status "Invalidating CloudFront cache..."
    
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    print_status "CloudFront invalidation created: $INVALIDATION_ID"
    print_warning "Cache invalidation may take 5-15 minutes to complete."
}

# Update contact.html with API endpoint
update_contact_form() {
    print_status "Updating contact form with API endpoint..."
    
    API_ENDPOINT=$(terraform output -raw api_endpoint)
    
    if [ -z "$API_ENDPOINT" ]; then
        print_warning "Could not get API endpoint from Terraform. Please update contact.html manually."
        return
    fi
    
    # Create a temporary file with updated API endpoint
    TEMP_FILE=$(mktemp)
    sed "s|YOUR_API_GATEWAY_ENDPOINT|$API_ENDPOINT|g" "$SITE_DIR/contact.html" > "$TEMP_FILE"
    
    # Upload the updated file
    aws s3 cp "$TEMP_FILE" "s3://$S3_BUCKET/contact.html" \
        --cache-control "public, max-age=3600" \
        --content-type "text/html"
    
    # Clean up temporary file
    rm "$TEMP_FILE"
    
    print_status "Contact form updated with API endpoint: $API_ENDPOINT"
    print_warning "Note: You'll need to manually update the reCAPTCHA site key in contact.html"
}

# Main deployment function
main() {
    print_status "Starting static site deployment..."
    
    check_dependencies
    get_terraform_outputs
    sync_to_s3
    update_contact_form
    invalidate_cloudfront
    
    print_status "Deployment completed successfully!"
    print_status "Your site should be available at: $(terraform output -raw site_url)"
    print_warning "Note: DNS propagation and CloudFront cache invalidation may take some time."
}

# Run main function
main "$@"
