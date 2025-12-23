# stop script on first error
$ErrorActionPreference = "Stop"

# Download CMake 3.29.2 from https://cmake.org/download/
$client = new-object System.Net.WebClient
$cmakeMsiPath = "C:\Install\cmake-windows-x86_64.msi"
$client.DownloadFile("https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-windows-x86_64.msi", $cmakeMsiPath)

# Install CMake
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $cmakeMsiPath, "/qn", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "CMake install failure"
}
