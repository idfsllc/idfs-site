# PowerShell script to help with image optimization
# Run this in the carousel-pics folder

Write-Host "=== Carousel Image Optimization Helper ===" -ForegroundColor Green
Write-Host ""
Write-Host "Current files in directory:" -ForegroundColor Yellow
Get-ChildItem -Name

Write-Host ""
Write-Host "=== File Sizes ===" -ForegroundColor Yellow
Get-ChildItem | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    $color = if ($sizeKB -gt 500) { "Red" } elseif ($sizeKB -gt 200) { "Yellow" } else { "Green" }
    Write-Host "$($_.Name): $sizeKB KB" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. Convert JPG files to WebP using https://squoosh.app/" -ForegroundColor White
Write-Host "2. Target file sizes under 200KB for best performance" -ForegroundColor White
Write-Host "3. Use 80% quality setting in Squoosh" -ForegroundColor White
Write-Host "4. Update HTML to use: assets/1920x1080-carousel-pics/filename.webp" -ForegroundColor White
Write-Host ""
Write-Host "Files needing conversion:" -ForegroundColor Red
Get-ChildItem -Filter "*.jpg" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Red }
