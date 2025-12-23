# stop script on first error
$ErrorActionPreference = "Stop"

# Download Git for Windows 2.44.0
$client = new-object System.Net.WebClient
$client.DownloadFile("https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe","C:\Install\Git-64-bit.exe")

# Install Git for Windows
$process = Start-Process -FilePath "C:\Install\Git-64-bit.exe" -ArgumentList "/silent" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Git install failure"
}

# Switch to schannel backend to access GEHC root CAs
# DOC: https://ge-hc.atlassian.net/wiki/spaces/GNA/pages/353877070/CA+Certificates
& "C:\Program Files\Git\cmd\git.exe" config --global http.sslBackend schannel
if ($LastExitCode -ne 0) {
    throw "Git schannel config failure"
}

# Configure GEHC proxy
& "C:\Program Files\Git\cmd\git.exe" config --global http.proxy http://proxy.net.ge-healthcare.net:8080
if ($LastExitCode -ne 0) {
    throw "Git proxy config failure"
}
