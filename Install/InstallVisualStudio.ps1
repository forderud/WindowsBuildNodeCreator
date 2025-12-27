# stop script on first error
$ErrorActionPreference = "Stop"

# command-line arguments
$vsVersion = $args[0] # Visual Studio version
if (-not $vsVersion) {
    throw "Visual Studio version parameter missing"
}

if ($vsVersion -eq "16/release.16.7") {
    # use download from Box
    Copy-Item "C:\Install\vs_Professional_16.7.exe" -Destination "C:\Install\vs_Professional.exe"
} else {
    Write-Host "Downloading Visual Studio $vsVersion bootstrapper..."
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://aka.ms/vs/"+$vsVersion+"/vs_professional.exe","C:\Install\vs_Professional.exe")
}

Write-Host "Installing Visual Studio $vsVersion with C++ and .Net..."
# Component list: https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-professional
$process = Start-Process -FilePath "C:\Install\vs_Professional.exe" -ArgumentList `
    "--add", "Microsoft.VisualStudio.Workload.NativeDesktop", `
    "--add", "Microsoft.VisualStudio.Component.VC.ATLMFC", `
    "--add", "Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64", `   # VS2019 build tools
    "--add", "Microsoft.VisualStudio.Component.VC.14.29.16.11.ATL", `
    "--add", "Microsoft.VisualStudio.Component.VC.14.29.16.11.MFC", `
    "--add", "Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64", `
    "--add", "Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre", ` # required for driver builds
    "--add", "Microsoft.VisualStudio.Workload.ManagedDesktop", `
    "--includeRecommended", "--passive", "--norestart", "--wait" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    # DOC: https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio#error-codes
    throw "Visual Studio install failure (ExitCode: {0})" -f $process.ExitCode
}

if ($vsVersion.Substring(0,2) -eq "17") {
    Write-Host "Downloading and install Windows Driver Kit (WDK) 10.0.22621.2428..."
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://go.microsoft.com/fwlink/?linkid=2249371","C:\Install\wdksetup.exe")

    $process = Start-Process -FilePath "C:\Install\wdksetup.exe" -ArgumentList "/features", "+", "/quiet" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "WDK installation failure (ExitCode: {0})" -f $process.ExitCode
    }

    Write-Host "Installing WDK Visual Studio extension..."
    $filePath = Resolve-Path -Path "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2022\*\WDK.vsix"
    $installerPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
    $process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$filePath`"") -Wait -PassThru

    Write-Host "Set VS170COMNTOOLS env.var. to VS2022 installation folder..."
    [Environment]::SetEnvironmentVariable("VS170COMNTOOLS", "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\", [EnvironmentVariableTarget]::Machine)
}

Write-Host "SUCCESS: Visual Studio $vsVersion installation completed."
