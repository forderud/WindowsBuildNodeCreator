# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading Docker..."
$client = new-object System.Net.WebClient
$exePath = "C:\Install\DockerDesktopInstaller.exe"
$client.DownloadFile("https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe", $exePath)

Write-Host "Installing Docker..."
# DOC: https://docs.docker.com/desktop/setup/install/windows-install
$process = Start-Process -FilePath $exePath -ArgumentList "install", "--accept-license", "--quiet" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    # Installation log on C:\Users\Administrator\AppData\Local\Docker\log\host\DockerDesktopInstaller.exe.log
    #Write-Host("Docker install failure (ExitCode: {0})" -f $process.ExitCode)
    #sleep 600 # sleep 10min to get a chance to debug
    throw "Docker install failure (ExitCode: {0})" -f $process.ExitCode
}
