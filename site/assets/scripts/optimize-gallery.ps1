# PowerShell script to optimize gallery images
# Run this in the Gallery-pics folder

Write-Host "=== Gallery Image Optimization Helper ===" -ForegroundColor Green
Write-Host ""
Write-Host "Current files in directory:" -ForegroundColor Yellow
Get-ChildItem -Name

Write-Host ""
Write-Host "=== File Analysis ===" -ForegroundColor Yellow
Get-ChildItem | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    $color = if ($sizeKB -gt 500) { "Red" } elseif ($sizeKB -gt 200) { "Yellow" } else { "Green" }
    Write-Host "$($_.Name): $sizeKB KB" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Gallery Image Requirements ===" -ForegroundColor Cyan
Write-Host "Target: 4:3 aspect ratio (800x600px recommended)" -ForegroundColor White
Write-Host "Format: WebP for best performance" -ForegroundColor White
Write-Host "Size: Under 200KB per image" -ForegroundColor White
Write-Host "Quality: 80-85% for good balance" -ForegroundColor White
Write-Host ""
Write-Host "Files needing conversion:" -ForegroundColor Red
Get-ChildItem -Filter "*.jpg", "*.jpeg", "*.png" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Red }
Write-Host ""
Write-Host "Files already WebP:" -ForegroundColor Green
Get-ChildItem -Filter "*.webp" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Green }
