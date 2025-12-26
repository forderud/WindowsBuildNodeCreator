# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading Packer..."
$zipPath = "C:\Install\packer.zip"
$client = new-object System.Net.WebClient
$client.DownloadFile("https://releases.hashicorp.com/packer/1.14.3/packer_1.14.3_windows_amd64.zip", $zipPath)

Write-Host "Unzipping Packer..."
Expand-Archive -Path $zipPath -DestinationPath C:\Install

Write-Host "Copying Packer.exe to BuildTools folder..."
$buildFolder = "C:\BuildTools"
[void](New-Item $buildFolder -Type Directory)
Copy-Item "C:\Install\packer.exe" -Destination $buildFolder

$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($machinePath -like "*$buildFolder*") {
    # already in PATH
} else {
    Write-Host "Adding BuildTools to machine-wide PATH..."
    $machinePath += ";$buildFolder"
    [Environment]::SetEnvironmentVariable("Path", $machinePath, [EnvironmentVariableTarget]::Machine)
}
