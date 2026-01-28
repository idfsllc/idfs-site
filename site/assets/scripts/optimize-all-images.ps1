# PowerShell script to convert all PNG, JPEG, JPG images to WebP
# Uses ImageMagick for conversion

param(
    [string]$AssetsPath = ".",
    [int]$Quality = 85
)

Write-Host "=== Image to WebP Conversion ===" -ForegroundColor Green
Write-Host ""

# Get all image files
$imageFiles = Get-ChildItem -Path $AssetsPath -Recurse -Include *.png,*.jpeg,*.jpg -File

if ($imageFiles.Count -eq 0) {
    Write-Host "No PNG/JPEG/JPG images found to convert." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($imageFiles.Count) images to convert" -ForegroundColor Cyan
Write-Host ""

$converted = 0
$skipped = 0
$errors = 0

foreach ($file in $imageFiles) {
    $webpPath = $file.FullName -replace '\.(png|jpeg|jpg)$', '.webp'
    
    # Skip if WebP already exists
    if (Test-Path $webpPath) {
        $originalSize = [math]::Round($file.Length / 1KB, 2)
        $webpSize = [math]::Round((Get-Item $webpPath).Length / 1KB, 2)
        $savings = [math]::Round((1 - ($webpSize / $originalSize)) * 100, 1)
        
        Write-Host "[OK] $($file.Name) - WebP exists ($($savings) percent smaller)" -ForegroundColor Green
        $skipped++
        continue
    }
    
    try {
        Write-Host "Converting: $($file.Name)..." -ForegroundColor Yellow
        
        # Get original size
        $originalSize = $file.Length
        
        # Convert to WebP using ImageMagick
        & magick "$($file.FullName)" -quality $Quality -define webp:method=6 "$webpPath"
        
        if (Test-Path $webpPath) {
            $newSize = (Get-Item $webpPath).Length
            $savings = [math]::Round((1 - ($newSize / $originalSize)) * 100, 1)
            $originalSizeKB = [math]::Round($originalSize / 1KB, 2)
            $newSizeKB = [math]::Round($newSize / 1KB, 2)
            
            Write-Host "  [OK] Created: $([System.IO.Path]::GetFileName($webpPath))" -ForegroundColor Green
            Write-Host "    Size: ${originalSizeKB}KB -> ${newSizeKB}KB ($($savings) percent reduction)" -ForegroundColor Cyan
            $converted++
        } else {
            Write-Host "  [ERROR] Failed to create WebP" -ForegroundColor Red
            $errors++
        }
    }
    catch {
        Write-Host "  [ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green
Write-Host "Converted: $converted" -ForegroundColor Cyan
Write-Host "Skipped (already exists): $skipped" -ForegroundColor Yellow
Write-Host "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Next step: Update HTML files to use .webp extensions" -ForegroundColor Yellow

