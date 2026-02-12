# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:NUGET_REPO_USER and $Env:NUGET_REPO_PW to have already been set
$repoUrl  = $Env:NUGET_REPO_URL
$username = $Env:NUGET_REPO_USER
$password = $Env:NUGET_REPO_PW

Write-Host "NuGet repo URL: $repoUrl"
Write-Host "NuGet username: $username"
Write-Host "NuGet password: $password"

# Add NuGet repo
$exePath = "C:\Install\nuget.exe"
$repoName = $repoUrl.Split("/")[-1]
& $exePath sources Add -Name $repoName -Source $repoUrl
if ($LastExitCode -ne 0) {
    throw "nuget.exe sources Add failure (ExitCode: {0})" -f $LastExitCode
}

if ((-not $username) -or (-not $password)) {
    Write-Host "SKIPPING NuGet authentication configuration."
} else {
    Write-Host "Configure NuGet authentication..."
    # Pass -StorePasswordInClearText to avoid "CryptographicException: Access is denied" errors on AWS
    & $exePath sources Update -Name $repoName -Username $username -Password $password -Verbosity detailed
    if ($LastExitCode -ne 0) {
        #Write-Host("nuget.exe sources Update failure (ExitCode: {0})" -f $LastExitCode)
        #sleep 1800 # sleep 30min to give time for interactive debugging
        throw "nuget.exe sources Update failure (ExitCode: {0})" -f $LastExitCode
    }

    # Gives "CryptographicException: Access is denied" errors on AWS
    $auth = "{0}:{1}" -f $username, $password
    & $exePath setapikey $auth -Source $repoName -Verbosity detailed
    if ($LastExitCode -ne 0) {
        throw "nuget.exe setapikey failure (ExitCode: {0})" -f $LastExitCode
    }
}

# Copy NuGet configuration to machine-wide folder
# DOC: https://learn.microsoft.com/en-us/nuget/consume-packages/configuring-nuget-behavior
Copy-Item "$Env:APPDATA\NuGet\NuGet.Config" -Destination "${Env:ProgramFiles(x86)}\NuGet\Config"
