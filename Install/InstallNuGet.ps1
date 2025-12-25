# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:ARTIFACTORY_USER and $Env:ARTIFACTORY_PW to have already been set
# or a ARTIFACTORY_CREDS file to be present.
$artifactoryCreds = "C:\Install\ARTIFACTORY_CREDS"
if (Test-Path $artifactoryCreds -PathType Leaf) {
    # set global env. variable
    $userpw = Get-Content -Path $artifactoryCreds
    $username = $userpw[0]
    $password = $userpw[1]
} else {
    $username = $Env:ARTIFACTORY_USER
    $password = $Env:ARTIFACTORY_PW
}

Write-Host "Downloading NuGet.exe..."
$client = new-object System.Net.WebClient
$client.DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe","C:\Install\nuget.exe")

# Add CVUS Artifactory repo
& "C:\Install\nuget.exe" sources Add -Name nuget-cvus-prod-all -Source https://eu-artifactory.apps.ge-healthcare.net/artifactory/api/nuget/nuget-cvus-prod-all
if ($LastExitCode -ne 0) {
    throw "nuget.exe sources Add failure"
}

Write-Host "Configure Artifactory authentication..."
& "C:\Install\nuget.exe" sources Update -Name nuget-cvus-prod-all -Username $username -Password $password
if ($LastExitCode -ne 0) {
    throw "nuget.exe sources Update failure"
}

$auth = "{0}:{1}" -f $username, $password
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
