# stop script on first error
$ErrorActionPreference = "Stop"

# Download page: https://cmake.org/download/
Write-Host "Downloading CMake..."
$client = new-object System.Net.WebClient
$cmakeMsiPath = "C:\Install\cmake-windows-x86_64.msi"
$client.DownloadFile("https://github.com/Kitware/CMake/releases/download/v4.2.1/cmake-4.2.1-windows-x86_64.msi", $cmakeMsiPath)

Write-Host "Installing CMake..."
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $cmakeMsiPath, "/qn", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "CMake install failure"
}
