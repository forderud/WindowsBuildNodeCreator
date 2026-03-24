# stop script on first error
$ErrorActionPreference = "Stop"

$certFile = "$PSScriptRoot/AUC.p12"

if (-not (Test-Path $certFile -PathType Leaf)) {
    Write-Host "SKIPPING Code signing configuration."
    exit 0
}

# download DigiCert One Signing Manager Tools smtools-windows-x64-1.62.msi (Box ID 2078884777880)
Write-Host "Downloading DigiCert One Signing Manager Tools..."
$msiPath = "C:\Install\smtools-windows-x64.msi"
& py "C:\Install\BoxDownload.py" 2078884777880 $msiPath
if ($LastExitCode -ne 0) {
    throw "smtools download failure (ExitCode: {0})" -f $LastExitCode
}

Write-Host "Installing DigiCert One Signing Manager Tools..."
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $msiPath, "/qn", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "DigiCert install failure (ExitCode: {0})" -f $process.ExitCode
}

Write-Host "Configuring code signing certificate...."

Copy-Item $certFile -Destination "C:\Program Files\DigiCert"

[Environment]::SetEnvironmentVariable("SM_HOST", "https://clientauth.one.digicert.com", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("SM_CLIENT_CERT_FILE", "C:\Program Files\DigiCert\AUC.p12", [EnvironmentVariableTarget]::Machine)
