# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading Git..."
$client = new-object System.Net.WebClient
$exePath = "C:\Install\Git-64-bit.exe"
$client.DownloadFile("https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe", $exePath)

Write-Host "Installing Git..."
$process = Start-Process -FilePath $exePath -ArgumentList "/silent" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Git install failure (ExitCode: {0})" -f $process.ExitCode
}

Write-Host "Switch to schannel backend to access GEHC root CAs..."
# DOC: https://ge-hc.atlassian.net/wiki/spaces/GNA/pages/353877070/CA+Certificates
& "C:\Program Files\Git\cmd\git.exe" config --global http.sslBackend schannel
if ($LastExitCode -ne 0) {
    throw "Git schannel config failure (ExitCode: {0})" -f $LastExitCode
}

Write-Host "Configuring GEHC proxy..."
& "C:\Program Files\Git\cmd\git.exe" config --global http.proxy http://proxy.net.ge-healthcare.net:8080
if ($LastExitCode -ne 0) {
    throw "Git proxy config failure (ExitCode: {0})" -f $LastExitCode
}
