$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "cmgzone/gitucli"
$InstallDir = "$env:USERPROFILE\.gitu-cli"
$BinDir = Join-Path $InstallDir "bin"
$ExePath = Join-Path $BinDir "gitu.exe"

Write-Host "Installing Gitu CLI..." -ForegroundColor Cyan

Write-Host "Finding latest release..." -ForegroundColor Yellow
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
$version = $release.tag_name
$asset = $release.assets | Where-Object { $_.name -eq "gitu-win-x64.exe" } | Select-Object -First 1

if (-not $asset) {
  Write-Host "No Windows asset found in latest release." -ForegroundColor Red
  exit 1
}

$downloadUrl = $asset.browser_download_url

Write-Host "Downloading $version..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$tmpPath = Join-Path $env:TEMP "gitu-win-x64.exe"
Invoke-WebRequest -Uri $downloadUrl -OutFile $tmpPath
Move-Item -Force $tmpPath $ExePath

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
if ($userPath -notlike "*$BinDir*") {
  $newPath = ($userPath.TrimEnd(';') + ";" + $BinDir).TrimStart(';')
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  $env:Path = $newPath + ";" + $env:Path
  Write-Host "Added to PATH for current user." -ForegroundColor Green
}

Write-Host "Gitu CLI installed to $ExePath" -ForegroundColor Green
Write-Host "Open a new terminal and run: gitu --help" -ForegroundColor Cyan
