@echo off
echo 🚀 Deploying IDFS Frontend Changes to AWS...
echo.

REM Check if we're in the right directory
if not exist "site\index.html" (
    echo ❌ Error: site\index.html not found. Are you in the project root?
    pause
    exit /b 1
)

REM Check if infra directory exists
if not exist "infra" (
    echo ❌ Error: infra directory not found. Run this from the project root.
    pause
    exit /b 1
)

echo 📋 Getting AWS resource information from Terraform...
cd infra
for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name') do set S3_BUCKET=%%i
for /f "tokens=*" %%i in ('terraform output -raw cloudfront_distribution_id') do set CLOUDFRONT_ID=%%i
cd ..

if "%S3_BUCKET%"=="" (
    echo ❌ Error: Could not get S3 bucket name from Terraform
    pause
    exit /b 1
)

if "%CLOUDFRONT_ID%"=="" (
    echo ❌ Error: Could not get CloudFront distribution ID from Terraform
    pause
    exit /b 1
)

echo ✅ S3 Bucket: %S3_BUCKET%
echo ✅ CloudFront Distribution ID: %CLOUDFRONT_ID%
echo.

echo 📤 Syncing frontend files to S3...
aws s3 sync site s3://%S3_BUCKET% --delete --cache-control "public, max-age=3600" --include "*.html"
aws s3 sync site s3://%S3_BUCKET% --cache-control "public, max-age=86400" --include "*.css" --include "*.js"
aws s3 sync site s3://%S3_BUCKET% --cache-control "public, max-age=31536000" --exclude "*.html" --exclude "*.css" --exclude "*.js"

if errorlevel 1 (
    echo ❌ Error: Failed to sync files to S3
    pause
    exit /b 1
)

echo ✅ Files synced to S3 successfully!
echo.

echo 🔄 Invalidating CloudFront cache...
aws cloudfront create-invalidation --distribution-id %CLOUDFRONT_ID% --paths "/*"

if errorlevel 1 (
    echo ❌ Error: Failed to invalidate CloudFront cache
    pause
    exit /b 1
)

echo ✅ CloudFront invalidation created successfully!
echo.

echo 🎉 Deployment completed successfully!
echo 🌐 Your site should be available at: https://d3lfqc6zal4ivs.cloudfront.net
echo 📝 Note: CloudFront cache invalidation may take 5-15 minutes to complete.
echo.

pause
