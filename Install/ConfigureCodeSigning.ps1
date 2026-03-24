# stop script on first error
$ErrorActionPreference = "Stop"

$authFile = "$PSScriptRoot/ssm-config.properties"

if (-not (Test-Path $authFile -PathType Leaf)) {
    Write-Host "SKIPPING Code signing configuration."
    exit 0
}

Write-Host "Configuring code signing for account...."

$ini = Get-Content -Path $authFile | ConvertFrom-StringData
$api_key = $ini.SM_API_KEY
$cert_pwd = $ini.SM_CLIENT_CERT_PASSWORD
& "C:\Program Files\DigiCert\DigiCert One Signing Manager Tools\smctl.exe" credentials save $api_key $cert_pwd
if ($LastExitCode -ne 0) {
    throw "smctl.exe credentials save (ExitCode: {0})" -f $LastExitCode
}

& "C:\Program Files\DigiCert\DigiCert One Signing Manager Tools\smctl.exe" windows certsync
if ($LastExitCode -ne 0) {
    throw "smctl.exe certsync failed (ExitCode: {0})" -f $LastExitCode
}
