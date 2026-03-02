# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading Python..."
$client = new-object System.Net.WebClient
$exePath = "C:\Install\python-amd64.exe"
$client.DownloadFile("https://www.python.org/ftp/python/3.14.2/python-3.14.2-amd64.exe", $exePath)

Write-Host "Installing Python..."
$process = Start-Process -FilePath $exePath -ArgumentList "/quiet", "InstallAllUsers=1" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Python installation failure (ExitCode: {0})" -f $process.ExitCode
}

Write-Host "Enable truststore feature for GEHC CA usage..."
# Doc: https://pip.pypa.io/en/stable/topics/https-certificates/
& "C:\Program Files\Python314\Scripts\pip.exe" config set global.use-feature truststore
if ($LastExitCode -ne 0) {
    throw "pip truststore failure (ExitCode: {0})" -f $LastExitCode
}

Write-Host "Installing python packages..."
# Packages required for Box download: truststore requests cryptography pyjwt
# Packages required for AppAPI: comtypes numpy matplotlib pywin32
# Package required for C++ python bindings: pybind11
& "C:\Program Files\Python314\Scripts\pip.exe" install truststore requests cryptography pyjwt comtypes numpy matplotlib pywin32 pybind11
if ($LastExitCode -ne 0) {
    throw "pip install failure (ExitCode: {0})" -f $LastExitCode
}
