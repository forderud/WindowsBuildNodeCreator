# stop script on first error
$ErrorActionPreference = "Stop"

# DOC: https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment
Write-Host "Downloading Docker Community Edition (CE) installation script..."

# Download script from https://github.com/microsoft/Windows-Containers
$scriptUrl = "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1"
Invoke-WebRequest -UseBasicParsing $scriptUrl -o "C:\Install\install-docker-ce.ps1"
