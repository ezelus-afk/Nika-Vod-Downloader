<#
.SYNOPSIS
    Python gerektirmeyen, Sifir-Log Kick, YouTube ve Twitch VOD Indirici.
    Tum indirme ve MP4 remux islemleri yerel bilgisayarda gerceklesir.
#>

$ErrorActionPreference = "Stop"
$SupabaseUrl = "https://wcdwovjokpuyvcvvquex.supabase.co"
$SupabaseKey = "sb_publishable_3SqSkaLTW0LotdYt5PBptA_qaKgJpC1"

$BaseDir = $PSScriptRoot
$BinDir = Join-Path $BaseDir "bin"
$DownloadDir = Join-Path $BaseDir "downloads"
$YtDlpExe = Join-Path $BinDir "yt-dlp.exe"
$FfmpegExe = Join-Path $BinDir "ffmpeg.exe"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null

function Get-PrivacyNotice {
    try {
        $headers = @{
            "apikey" = $SupabaseKey
            "Authorization" = "Bearer $SupabaseKey"
        }
        $response = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/app_config?id=eq.1&select=privacy_notice" -Headers $headers -Method Get -TimeoutSec 5
        if ($response.privacy_notice) {
            Write-Host "
============================================================" -ForegroundColor DarkGray
            Write-Host $response.privacy_notice -ForegroundColor Green
            Write-Host "============================================================
" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "[GIZLILIK] Cevrimdisi gizlilik modu aktif." -ForegroundColor Green
    }
}

function Initialize-Tools {
    if (-not (Test-Path $YtDlpExe)) {
        Write-Host "[KURULUM] Acik kaynakli yt-dlp motoru indiriliyor..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile $YtDlpExe
    }

    if (-not (Test-Path $FfmpegExe)) {
        Write-Host "[KURULUM] Acik kaynakli FFmpeg MP4 birlestirici indiriliyor..." -ForegroundColor Cyan
        $zipPath = Join-Path $BinDir "ffmpeg.zip"
        $extractPath = Join-Path $BinDir "ffmpeg_temp"
        Invoke-WebRequest -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        $foundFfmpeg = Get-ChildItem -Path $extractPath -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1
        Move-Item -Path $foundFfmpeg.FullName -Destination $FfmpegExe -Force
        Remove-Item -Path $zipPath, $extractPath -Recurse -Force
    }
}

Clear-Host
Write-Host "=== SIFIR-LOG VOD ARCHIVER (KICK / YOUTUBE / TWITCH) ===" -ForegroundColor Cyan
Get-PrivacyNotice
Initialize-Tools

while ($true) {
    $vodUrl = Read-Host "
Yayin Tekrari (VOD) Linkini Yapistirin (Cikis icin 'q')"
    if ($vodUrl -eq 'q' -or $vodUrl -eq 'Q') { break }
    if ([string]::IsNullOrWhiteSpace($vodUrl)) { continue }

    Write-Host "
Kalite kaybi olmadan (Remux) edit uyumlu MP4 olarak indiriliyor..." -ForegroundColor Yellow

    $ytArgs = @(
        "--ffmpeg-location", $BinDir,
        "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best",
        "--merge-output-format", "mp4",
        "--no-cache-dir",
        "--no-write-info-json",
        "--no-write-thumbnail",
        "-o", "$DownloadDir\%(uploader)s - %(title)s [%(id)s].%(ext)s",
        $vodUrl
    )

    & $YtDlpExe @ytArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "
[BASARILI] Video edit programlarina hazir sekilde kaydedildi: $DownloadDir" -ForegroundColor Green
    } else {
        Write-Host "
[HATA] Indirme tamamlanamadi. Linkin herkese acik bir VOD oldugundan emin olun." -ForegroundColor Red
    }
}
