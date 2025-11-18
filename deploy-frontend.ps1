# PowerShell script to deploy frontend changes to AWS
# This script syncs only the /site directory to S3 and invalidates CloudFront cache

param(
    [switch]$DryRun = $false
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Check if AWS CLI is available
function Test-AWSCLI {
    try {
        $null = aws --version
        return $true
    }
    catch {
        return $false
    }
}

# Get Terraform outputs
function Get-TerraformOutputs {
    Write-Status "Getting Terraform outputs..."
    
    $terraformDir = "infra"
    if (-not (Test-Path "$terraformDir/terraform.tfstate")) {
        Write-Error "terraform.tfstate not found in $terraformDir. Please run 'terraform apply' first."
        exit 1
    }
    
    Push-Location $terraformDir
    try {
        $s3Bucket = terraform output -raw s3_bucket_name
        $cloudfrontId = terraform output -raw cloudfront_distribution_id
        
        if (-not $s3Bucket -or -not $cloudfrontId) {
            Write-Error "Failed to get Terraform outputs. Please check your Terraform state."
            exit 1
        }
        
        Write-Status "S3 Bucket: $s3Bucket"
        Write-Status "CloudFront Distribution ID: $cloudfrontId"
        
        return @{
            S3Bucket = $s3Bucket
            CloudFrontId = $cloudfrontId
        }
    }
    finally {
        Pop-Location
    }
}

# Sync files to S3
function Sync-ToS3 {
    param(
        [string]$S3Bucket,
        [string]$SiteDir
    )
    
    Write-Status "Syncing files to S3..."
    Write-Status "Syncing from: $SiteDir"
    
    if (-not (Test-Path $SiteDir)) {
        Write-Error "Site directory not found: $SiteDir"
        exit 1
    }
    
    if ($DryRun) {
        Write-Status "DRY RUN: Would sync $SiteDir to s3://$S3Bucket"
        return
    }
    
    # Sync static assets with long cache
    Write-Status "Syncing static assets (images, fonts, etc.)..."
    aws s3 sync "$SiteDir" "s3://$S3Bucket" `
        --delete `
        --cache-control "public, max-age=31536000" `
        --exclude "*.html" `
        --exclude "*.css" `
        --exclude "*.js" `
        --exclude "*.xml" `
        --exclude "*.txt"
    
    # Sync HTML files with shorter cache
    Write-Status "Syncing HTML files..."
    aws s3 sync "$SiteDir" "s3://$S3Bucket" `
        --cache-control "public, max-age=3600" `
        --include "*.html"
    
    # Sync CSS and JS files with medium cache
    Write-Status "Syncing CSS and JS files..."
    aws s3 sync "$SiteDir" "s3://$S3Bucket" `
        --cache-control "public, max-age=86400" `
        --include "*.css" `
        --include "*.js"
    
    # Sync XML and TXT files
    Write-Status "Syncing XML and TXT files..."
    aws s3 sync "$SiteDir" "s3://$S3Bucket" `
        --cache-control "public, max-age=3600" `
        --include "*.xml" `
        --include "*.txt"
    
    Write-Status "Files synced to S3 successfully."
}

# Invalidate CloudFront cache
function Invoke-CloudFrontInvalidation {
    param([string]$CloudFrontId)
    
    Write-Status "Invalidating CloudFront cache..."
    
    if ($DryRun) {
        Write-Status "DRY RUN: Would invalidate CloudFront distribution $CloudFrontId"
        return
    }
    
    $invalidationId = aws cloudfront create-invalidation `
        --distribution-id $CloudFrontId `
        --paths "/*" `
        --query 'Invalidation.Id' `
        --output text
    
    Write-Status "CloudFront invalidation created: $invalidationId"
    Write-Warning "Cache invalidation may take 5-15 minutes to complete."
}

# Main deployment function
function Start-Deployment {
    Write-Status "Starting frontend deployment to AWS..."
    
    # Check dependencies
    if (-not (Test-AWSCLI)) {
        Write-Error "AWS CLI is not installed or not in PATH. Please install it first."
        exit 1
    }
    
    # Get Terraform outputs
    $outputs = Get-TerraformOutputs
    
    # Get site directory path
    $siteDir = "site"
    if (-not (Test-Path $siteDir)) {
        Write-Error "Site directory not found: $siteDir"
        exit 1
    }
    
    # Sync to S3
    Sync-ToS3 -S3Bucket $outputs.S3Bucket -SiteDir $siteDir
    
    # Invalidate CloudFront
    Invoke-CloudFrontInvalidation -CloudFrontId $outputs.CloudFrontId
    
    Write-Status "Deployment completed successfully!"
    Write-Status "Your site should be available at: https://$($outputs.CloudFrontId).cloudfront.net"
    Write-Warning "Note: CloudFront cache invalidation may take 5-15 minutes to complete."
}

# Run deployment
Start-Deployment
