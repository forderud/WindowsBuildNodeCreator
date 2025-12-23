# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading NuGet.exe..."
$client = new-object System.Net.WebClient
$client.DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe","C:\Install\nuget.exe")

# Add CVUS Artifactory repo
& "C:\Install\nuget.exe" sources Add -Name nuget-cvus-prod-all -Source https://eu-artifactory.apps.ge-healthcare.net/artifactory/api/nuget/nuget-cvus-prod-all
if ($LastExitCode -ne 0) {
    throw "nuget.exe sources Add failure"
}

# require ARTIFACTORY_CREDS file
$artifactoryCreds = "C:\Install\ARTIFACTORY_CREDS"
if (Test-Path $artifactoryCreds -PathType Leaf) {
    # set global env. variable
    $userpw = Get-Content -Path $artifactoryCreds
} else {
    Write-Host "Skipping NuGet configuration due to lack of credentials."
    exit 1
}

Write-Host "Configure Artifactory authentication..."
& "C:\Install\nuget.exe" sources Update -Name nuget-cvus-prod-all -Username $userpw[0] -Password $userpw[1]
if ($LastExitCode -ne 0) {
    throw "nuget.exe sources Update failure"
}

$auth = "{0}:{1}" -f $userpw[0], $userpw[1]
& "C:\Install\nuget.exe" setapikey $auth -Source nuget-cvus-prod-all
if ($LastExitCode -ne 0) {
    throw "nuget.exe setapikey failure"
}

Write-Host "Copying NuGet.exe to new BuildTools folder..."
$buildFolder = "C:\BuildTools"
[void](New-Item $buildFolder -Type Directory)
Copy-Item "C:\Install\nuget.exe" -Destination $buildFolder

Write-Host "Add folder to machine-wide PATH..."
$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$machinePath += ";$buildFolder"
[Environment]::SetEnvironmentVariable("Path", $machinePath, [EnvironmentVariableTarget]::Machine)
