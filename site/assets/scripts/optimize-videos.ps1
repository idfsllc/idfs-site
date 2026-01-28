# PowerShell script to optimize video files
# Requires ffmpeg to be installed

param(
    [string]$AssetsPath = ".",
    [int]$MaxWidth = 1920,
    [int]$MaxHeight = 1080,
    [int]$Bitrate = 2000,
    [int]$AudioBitrate = 128
)

Write-Host "=== Video Optimization ===" -ForegroundColor Green
Write-Host ""

# Check for ffmpeg
$ffmpegPath = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegPath) {
    Write-Host "ERROR: ffmpeg not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install ffmpeg:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://ffmpeg.org/download.html" -ForegroundColor White
    Write-Host "2. Or use: winget install ffmpeg" -ForegroundColor White
    Write-Host "3. Or use: choco install ffmpeg" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Use online tools like:" -ForegroundColor Yellow
    Write-Host "- https://www.freeconvert.com/video-compressor" -ForegroundColor White
    Write-Host "- https://cloudconvert.com/mp4-converter" -ForegroundColor White
    exit 1
}

Write-Host "Using ffmpeg: $($ffmpegPath.Source)" -ForegroundColor Cyan
Write-Host ""

# Get all video files
$videoFiles = Get-ChildItem -Path $AssetsPath -Recurse -Include *.mp4,*.mov,*.avi -File

if ($videoFiles.Count -eq 0) {
    Write-Host "No video files found to optimize." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($videoFiles.Count) videos to optimize" -ForegroundColor Cyan
Write-Host ""

$optimized = 0
$skipped = 0
$errors = 0

foreach ($file in $videoFiles) {
    $optimizedPath = $file.DirectoryName + "\" + $file.BaseName + "_optimized.mp4"
    
    # Skip if optimized version already exists
    if (Test-Path $optimizedPath) {
        Write-Host "[OK] $($file.Name) - Optimized version exists" -ForegroundColor Green
        $skipped++
        continue
    }
    
    try {
        Write-Host "Optimizing: $($file.Name)..." -ForegroundColor Yellow
        
        # Get original size
        $originalSize = $file.Length
        $originalSizeMB = [math]::Round($originalSize / 1MB, 2)
        
        Write-Host "  Original size: ${originalSizeMB}MB" -ForegroundColor Cyan
        
        # Optimize video with ffmpeg
        # -vf scale: Resize if larger than max dimensions
        # -c:v libx264: Use H.264 codec
        # -preset medium: Balance between speed and compression
        # -crf 28: Quality (lower = better quality, higher = smaller file)
        # -c:a aac: Audio codec
        # -movflags +faststart: Enable fast start for web playback
        
        $ffmpegArgs = @(
            "-i", "`"$($file.FullName)`"",
            "-vf", "scale='if(gt(iw,$MaxWidth),$MaxWidth,-1)':'if(gt(ih,$MaxHeight),$MaxHeight,-1)'",
            "-c:v", "libx264",
            "-preset", "medium",
            "-crf", "28",
            "-maxrate", "${Bitrate}k",
            "-bufsize", "$($Bitrate * 2)k",
            "-c:a", "aac",
            "-b:a", "${AudioBitrate}k",
            "-movflags", "+faststart",
            "-y",
            "`"$optimizedPath`""
        )
        
        $process = Start-Process -FilePath $ffmpegPath.Source -ArgumentList $ffmpegArgs -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0 -and (Test-Path $optimizedPath)) {
            $newSize = (Get-Item $optimizedPath).Length
            $newSizeMB = [math]::Round($newSize / 1MB, 2)
            $savings = [math]::Round((1 - ($newSize / $originalSize)) * 100, 1)
            
            Write-Host "  [OK] Created: $([System.IO.Path]::GetFileName($optimizedPath))" -ForegroundColor Green
            Write-Host "    Size: ${originalSizeMB}MB -> ${newSizeMB}MB ($($savings) percent reduction)" -ForegroundColor Cyan
            $optimized++
        } else {
            Write-Host "  [ERROR] Failed to optimize video" -ForegroundColor Red
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
Write-Host "Optimized: $optimized" -ForegroundColor Cyan
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
Write-Host "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review optimized videos" -ForegroundColor White
Write-Host "2. Replace original files if quality is acceptable" -ForegroundColor White
Write-Host "3. Update HTML to use optimized video files" -ForegroundColor White

