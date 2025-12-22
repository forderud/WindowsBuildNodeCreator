# stop script on first error
$ErrorActionPreference = "Stop"

# command-line arguments
$vsVersion = $args[0] # Visual Studio version
if ($vsVersion -eq $null) {
    throw "Visual Studio version parameter missing"
}

# Download Visual Studio bootstrapper
$client = new-object System.Net.WebClient
$client.DownloadFile("https://aka.ms/vs/"+$vsVersion+"/vs_professional.exe","C:\Install\vs_Professional.exe")

# Install Visual Studio with C++ and .Net
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
    "--includeRecommended", "--passive", "--wait" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Visual Studio install failure"
}

if ($vsVersion.Substring(0,2) -eq "17") {
    # Download and install Windows Driver Kit (WDK) 10.0.22621.2428
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://go.microsoft.com/fwlink/?linkid=2249371","C:\Install\wdksetup.exe")

    $process = Start-Process -FilePath "C:\Install\wdksetup.exe" -ArgumentList "/features", "+", "/quiet" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "WDK installation failure"
    }

    # Install WDK Visual Studio extension
    $filePath = Resolve-Path -Path "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2022\*\WDK.vsix"
    $installerPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
    $process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$filePath`"") -Wait -PassThru

    # Set VS170COMNTOOLS env.var. to VS2022 installation folder
    [Environment]::SetEnvironmentVariable("VS170COMNTOOLS", "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\", [EnvironmentVariableTarget]::Machine)
}
