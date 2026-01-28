# Master script to optimize all site assets
# Converts images to WebP and optimizes videos

param(
    [switch]$ImagesOnly = $false,
    [switch]$VideosOnly = $false
)

Write-Host "=== IDFS Site Asset Optimization ===" -ForegroundColor Green
Write-Host ""

$sitePath = "site\assets"

if (-not (Test-Path $sitePath)) {
    Write-Host "ERROR: Site assets directory not found: $sitePath" -ForegroundColor Red
    exit 1
}

# Optimize images
if (-not $VideosOnly) {
    Write-Host "=== Step 1: Converting Images to WebP ===" -ForegroundColor Cyan
    Write-Host ""
    
    $imageScript = "$sitePath\scripts\optimize-all-images.ps1"
    if (Test-Path $imageScript) {
        Push-Location $sitePath
        try {
            & powershell -ExecutionPolicy Bypass -File "scripts\optimize-all-images.ps1" -AssetsPath "." -Quality 85
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Host "WARNING: Image optimization script not found" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Optimize videos
if (-not $ImagesOnly) {
    Write-Host "=== Step 2: Optimizing Videos ===" -ForegroundColor Cyan
    Write-Host ""
    
    $videoScript = "$sitePath\scripts\optimize-videos.ps1"
    if (Test-Path $videoScript) {
        Push-Location $sitePath
        try {
            & powershell -ExecutionPolicy Bypass -File "scripts\optimize-videos.ps1" -AssetsPath "." -MaxWidth 1920 -MaxHeight 1080 -Bitrate 2000
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Host "WARNING: Video optimization script not found" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "=== Optimization Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review optimized files" -ForegroundColor White
Write-Host "2. Update HTML references to use .webp images" -ForegroundColor White
Write-Host "3. Replace original videos with optimized versions if quality is acceptable" -ForegroundColor White
Write-Host "4. Test the site to ensure everything works" -ForegroundColor White
Write-Host "5. Deploy updated assets" -ForegroundColor White

