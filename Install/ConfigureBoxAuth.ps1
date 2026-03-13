# stop script on first error
$ErrorActionPreference = "Stop"

$authFile = "$PSScriptRoot/box_settings.json"

if (-not (Test-Path $authFile -PathType Leaf)) {
    Write-Host "SKIPPING Box authentication configuration."
    exit 0
}

Write-Host "Configuring Box authentication for SYSTEM account...."
Copy-Item $authFile -Destination "C:\Windows\System32\config\systemprofile"

Write-Host "Configuring Box authentication for current account...."
$userprofile = [Environment]::GetEnvironmentVariable("USERPROFILE")
Copy-Item $authFile -Destination $userprofile
