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
    $repoUrl  = $userpw[2]
} else {
    $username = $Env:ARTIFACTORY_USER
    $password = $Env:ARTIFACTORY_PW
    $repoUrl  = "https://eu-artifactory.apps.ge-healthcare.net/artifactory/api/nuget/nuget-cvus-prod-all"
}

Write-Host "Downloading NuGet.exe..."
$client = new-object System.Net.WebClient
$exePath = "C:\Install\nuget.exe"
$client.DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe", $exePath)

if ($repoUrl) {
    # Add NuGet repo
    $repoName = $repoUrl.Split("/")[-1]
    & $exePath sources Add -Name $repoName -Source $repoUrl
    if ($LastExitCode -ne 0) {
        throw "nuget.exe sources Add failure (ExitCode: {0})" -f $LastExitCode
    }
}

if ((-not $username) -or (-not $password)) {
    Write-Host "Skipping NuGet authentication configuration."
} else {
    Write-Host "Configure NuGet authentication..."
    & $exePath sources Update -Name $repoName -Username $username -Password $password
    if ($LastExitCode -ne 0) {
        throw "nuget.exe sources Update failure (ExitCode: {0})" -f $LastExitCode
    }

    $auth = "{0}:{1}" -f $username, $password
    & $exePath setapikey $auth -Source $repoName
    if ($LastExitCode -ne 0) {
        throw "nuget.exe setapikey failure (ExitCode: {0})" -f $LastExitCode
    }
}

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
