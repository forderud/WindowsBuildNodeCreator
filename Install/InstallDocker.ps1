# stop script on first error
$ErrorActionPreference = "Stop"

# DOC: https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment

Write-Host "Downloading Docker Community Edition (CE) installation script..."
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -o install-docker-ce.ps1

Write-Host "Installing Docker CE..."
.\install-docker-ce.ps1
