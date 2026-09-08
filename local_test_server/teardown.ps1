# ============================================================
# teardown.ps1 — Stop and clean up the local OpenVPN test server
#
# Run from the local_test_server\ directory:
#   cd local_test_server
#   .\teardown.ps1
#
# Options (prompted interactively):
#   • Stop only — keeps PKI data so you can restart without re-generating certs
#   • Full wipe — removes PKI data (next setup.ps1 run will regenerate everything)
# ============================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataDir = Join-Path $ScriptDir "data"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  VPN App — Stopping Local Test Server" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Stop the container
Write-Host "Stopping OpenVPN container..." -ForegroundColor Yellow
docker-compose -f "$ScriptDir\docker-compose.yml" down
Write-Host "Container stopped." -ForegroundColor Green
Write-Host ""

# Ask whether to wipe PKI data
$wipe = Read-Host "Delete PKI data (./data)? This requires re-running setup.ps1 next time. [y/N]"
if ($wipe -eq "y" -or $wipe -eq "Y") {
    if (Test-Path $DataDir) {
        Remove-Item -Recurse -Force $DataDir
        Write-Host "PKI data deleted." -ForegroundColor Green
    }
    # Remove exported client profile
    $clientOvpn = Join-Path $ScriptDir "local-test.ovpn"
    if (Test-Path $clientOvpn) {
        Remove-Item -Force $clientOvpn
    }
} else {
    Write-Host "PKI data kept. Run 'docker-compose up -d' to restart quickly." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Done. Remember to set kLocalTestMode = true in vpn_service.dart" -ForegroundColor Yellow
Write-Host "if you want to continue testing without the server." -ForegroundColor Yellow
Write-Host ""
