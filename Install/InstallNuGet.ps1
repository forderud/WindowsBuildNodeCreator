# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading NuGet.exe..."
$client = new-object System.Net.WebClient
$exePath = "C:\Install\nuget.exe"
$client.DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe", $exePath)

Write-Host "Copying NuGet.exe to new BuildTools folder..."
$buildFolder = "C:\BuildTools"
if (-not (Test-Path $buildFolder -PathType Container)) {
    [void](New-Item $buildFolder -Type Directory)
}
Copy-Item $exePath -Destination $buildFolder

$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($machinePath -like "*$buildFolder*") {
    # already in PATH
} else {
    Write-Host "Adding BuildTools to machine-wide PATH..."
    $machinePath += ";$buildFolder"
    [Environment]::SetEnvironmentVariable("Path", $machinePath, [EnvironmentVariableTarget]::Machine)
}
