$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "cmgzone/gitucli"
$InstallDir = "$env:USERPROFILE\.gitu-cli"
$BinDir = Join-Path $InstallDir "bin"
$ExePath = Join-Path $BinDir "gitu.exe"

Write-Host "Installing Gitu CLI..." -ForegroundColor Cyan

Write-Host "Finding latest release..." -ForegroundColor Yellow
$headers = @{
  "Accept" = "application/vnd.github+json"
  "User-Agent" = "gitucli-installer"
  "X-GitHub-Api-Version" = "2022-11-28"
}

$release = $null
try {
  $release = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$Repo/releases/latest"
} catch {
  $statusCode = $null
  if ($_.Exception -and $_.Exception.Response -is [System.Net.HttpWebResponse]) {
    $statusCode = [int]$_.Exception.Response.StatusCode
  }

  if ($statusCode -eq 404) {
    $release = $null
  } else {
    throw
  }
}

if (-not $release) {
  Write-Host "No GitHub Release found yet for $Repo." -ForegroundColor Yellow

  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) {
    Write-Host "Falling back to npm install (requires Node.js/npm)..." -ForegroundColor Yellow
    & $npm.Source install -g "@notebookllm/gitu-cli"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Installed via npm. Open a new terminal and run: gitu --help" -ForegroundColor Cyan
    exit 0
  }

  Write-Host "Install requires either a GitHub Release (binary) or Node.js/npm." -ForegroundColor Red
  Write-Host "If you maintain the repo, create a release by pushing a tag like: git tag v1.0.1 ; git push origin v1.0.1" -ForegroundColor Yellow
  exit 1
}
$version = $release.tag_name
$asset = $release.assets | Where-Object { $_.name -eq "gitu-win-x64.exe" } | Select-Object -First 1

if (-not $asset) {
  Write-Host "No Windows asset found in latest release." -ForegroundColor Yellow
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) {
    Write-Host "Falling back to npm install (requires Node.js/npm)..." -ForegroundColor Yellow
    & $npm.Source install -g "@notebookllm/gitu-cli"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Installed via npm. Open a new terminal and run: gitu --help" -ForegroundColor Cyan
    exit 0
  }

  Write-Host "To install the Windows binary, publish a release that includes gitu-win-x64.exe." -ForegroundColor Red
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
