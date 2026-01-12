# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:NUGET_REPO_USER and $Env:NUGET_REPO_PW to have already been set
# or a ARTIFACTORY_CREDS file to be present.
$artifactoryCreds = "C:\Install\ARTIFACTORY_CREDS"
if (Test-Path $artifactoryCreds -PathType Leaf) {
    # set global env. variable
    $creds = Get-Content -Path $artifactoryCreds
    $username = $creds[0]
    $password = $creds[1]
    $repoUrl  = $creds[2]
} else {
    $repoUrl  = $Env:NUGET_REPO_URL
    $username = $Env:NUGET_REPO_USER
    $password = $Env:NUGET_REPO_PW
}

Write-Host "NuGet repo URL: $repoUrl"
Write-Host "NuGet username: $username"
Write-Host "NuGet password: $password"

Write-Host "Downloading NuGet.exe..."
$client = new-object System.Net.WebClient
$exePath = "C:\Install\nuget.exe"
$client.DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe", $exePath)

if (-not $repoUrl) {
    Write-Host "Skipping NuGet repo configuration."
} else {
    # Add NuGet repo
    $repoName = $repoUrl.Split("/")[-1]
    & $exePath sources Add -Name $repoName -Source $repoUrl
    if ($LastExitCode -ne 0) {
        throw "nuget.exe sources Add failure (ExitCode: {0})" -f $LastExitCode
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
