# ============================================================
# setup.ps1 — One-shot local OpenVPN test server setup
#
# Prerequisites:
#   • Docker Desktop (with WSL2 backend) installed and running
#   • Run from the local_test_server\ directory:
#       cd local_test_server
#       .\setup.ps1
#
# What this script does:
#   1. Generates PKI (CA + server cert) inside the Docker container
#   2. Creates a "local-test" client certificate
#   3. Exports a full .ovpn client profile
#   4. Updates all asset configs in the Flutter app to use localhost
#   5. Starts the OpenVPN server in the background
# ============================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigsDir = Join-Path $ProjectRoot "assets\vpn_configs"
$DataDir = Join-Path $ScriptDir "data"
$ClientName = "local-test"

# Host IP the Android emulator uses to reach the Windows host
$EmulatorHostIp = "10.0.2.2"
$VpnPort = 1194

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  VPN App — Local Test Server Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Check Docker is running ──────────────────────────────────────────
Write-Host "[1/6] Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "      Docker is running." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker Desktop is not running. Please start it and retry." -ForegroundColor Red
    exit 1
}

# ── Step 2: Create data directory ────────────────────────────────────────────
Write-Host "[2/6] Creating PKI data directory..." -ForegroundColor Yellow
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir | Out-Null
}
Write-Host "      $DataDir" -ForegroundColor Green

# ── Step 3: Generate server config + PKI ─────────────────────────────────────
Write-Host "[3/6] Generating OpenVPN server config and PKI (this may take ~60 s)..." -ForegroundColor Yellow

# Generate server.conf pointing at localhost
docker-compose -f "$ScriptDir\docker-compose.yml" run --rm openvpn `
    ovpn_genconfig -u "udp://$EmulatorHostIp"

# Initialize the PKI (no passphrase for local testing convenience)
docker-compose -f "$ScriptDir\docker-compose.yml" run --rm `
    -e EASYRSA_BATCH=1 `
    -e EASYRSA_REQ_CN="LocalTestCA" `
    openvpn ovpn_initpki nopass

Write-Host "      PKI generated." -ForegroundColor Green

# ── Step 4: Create client certificate ────────────────────────────────────────
Write-Host "[4/6] Creating client certificate '$ClientName'..." -ForegroundColor Yellow
docker-compose -f "$ScriptDir\docker-compose.yml" run --rm `
    -e EASYRSA_BATCH=1 `
    openvpn easyrsa build-client-full $ClientName nopass

Write-Host "      Client certificate created." -ForegroundColor Green

# ── Step 5: Export .ovpn client profile ──────────────────────────────────────
Write-Host "[5/6] Exporting client .ovpn profile..." -ForegroundColor Yellow

$ClientOvpn = docker-compose -f "$ScriptDir\docker-compose.yml" run --rm `
    openvpn ovpn_getclient $ClientName

# Save the exported profile for reference
$ExportPath = Join-Path $ScriptDir "$ClientName.ovpn"
$ClientOvpn | Set-Content -Encoding UTF8 $ExportPath
Write-Host "      Saved to: $ExportPath" -ForegroundColor Green

# ── Step 6: Update Flutter asset configs ─────────────────────────────────────
Write-Host "[6/6] Updating Flutter asset .ovpn configs to use local server..." -ForegroundColor Yellow

# Country → asset file map
$Servers = @{
    "us" = "United States"
    "uk" = "United Kingdom"
    "de" = "Germany"
    "jp" = "Japan"
    "sg" = "Singapore"
    "au" = "Australia"
    "ca" = "Canada"
    "nl" = "Netherlands"
}

foreach ($code in $Servers.Keys) {
    $assetPath = Join-Path $ConfigsDir "$code.ovpn"
    # Replace the exported profile's remote line with the local IP+port,
    # then write it into the asset file so every "server" uses the local box.
    $localConfig = $ClientOvpn -replace "remote .+ \d+", "remote $EmulatorHostIp $VpnPort"
    $localConfig | Set-Content -Encoding UTF8 $assetPath
    Write-Host "      Updated: $code.ovpn" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Starting OpenVPN server..." -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

docker-compose -f "$ScriptDir\docker-compose.yml" up -d

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Server: udp://$EmulatorHostIp:$VpnPort" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. In vpn_service.dart set:  const bool kLocalTestMode = false;" -ForegroundColor White
Write-Host "  2. Run the Flutter app on the Android emulator." -ForegroundColor White
Write-Host "  3. Tap Connect — the app will tunnel through your local server." -ForegroundColor White
Write-Host ""
Write-Host "  To stop the server:  .\teardown.ps1" -ForegroundColor DarkGray
Write-Host ""
