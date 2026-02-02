# stop script on first error
$ErrorActionPreference = "Stop"

# Download page: https://cmake.org/download/
Write-Host "Downloading CMake..."
$client = new-object System.Net.WebClient
$msiPath = "C:\Install\cmake-windows-x86_64.msi"
$client.DownloadFile("https://github.com/Kitware/CMake/releases/download/v4.2.3/cmake-4.2.3-windows-x86_64.msi", $msiPath)

Write-Host "Installing CMake..."
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $msiPath, "/qn", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "CMake install failure (ExitCode: {0})" -f $process.ExitCode
}
