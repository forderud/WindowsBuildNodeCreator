# stop script on first error
$ErrorActionPreference = "Stop"

# DOC: https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment

Write-Host "Downloading Docker Community Edition (CE) installation script..."

$scriptUrl = "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" # upstream version
#$scriptUrl = "https://raw.githubusercontent.com/forderud/Windows-Containers/refs/heads/ExecutionPolicy/helpful_tools/Install-DockerCE/install-docker-ce.ps1" # ExecutionPolicy modification

Invoke-WebRequest -UseBasicParsing $scriptUrl -o "C:\Install\install-docker-ce.ps1"
