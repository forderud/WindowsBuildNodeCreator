# stop script on first error
$ErrorActionPreference = "Stop"

$authFile = "$PSScriptRoot/ssm-config.properties"
$certFile = "$PSScriptRoot/AUC.p12"

if (-not (Test-Path $authFile -PathType Leaf)) {
    Write-Host "SKIPPING Code signing configuration."
    exit 0
}

Write-Host "Installing DigiCert One Signing Manager Tools..."

$msiPath = "C:\Install\smtools-windows-x64.msi"
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $msiPath, "/qn", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "DigiCert install failure (ExitCode: {0})" -f $process.ExitCode
}

Write-Host "Configuring code signing for SYSTEM account...."

$cfgFolder = "C:\Windows\System32\config\systemprofile\.signingmanager"
if (-not (Test-Path $cfgFolder -PathType Container)) {
    [void](New-Item $cfgFolder -Type Directory)
}
Copy-Item $authFile -Destination $cfgFolder

Write-Host "Configuring code signing for current account...."
$cfgFolder = [Environment]::GetEnvironmentVariable("USERPROFILE") + "\.signingmanager"
if (-not (Test-Path $cfgFolder -PathType Container)) {
    [void](New-Item $cfgFolder -Type Directory)
}
Copy-Item $authFile -Destination $cfgFolder

Copy-Item $certFile -Destination "C:\Program Files\DigiCert"

[Environment]::SetEnvironmentVariable("SM_HOST", "https://clientauth.one.digicert.com", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("SM_CLIENT_CERT_FILE", "C:\Program Files\DigiCert\AUC.p12", [EnvironmentVariableTarget]::Machine)

& "C:\Program Files\DigiCert\DigiCert One Signing Manager Tools\smctl.exe" windows certsync
if ($process.ExitCode -ne 0) {
    throw "smctl.exe certsync failed (ExitCode: {0})" -f $process.ExitCode
}
