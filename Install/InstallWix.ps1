# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading Wix toolset v3.14..."
$filePath = "C:\Install\wix314.exe"
$client = new-object System.Net.WebClient
$client.DownloadFile("https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe", $filePath)
Write-Host "Installing Wix 3..."
$process = Start-Process -FilePath $filePath -ArgumentList "/install", "/quiet", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Wix 3 install failure"
}

Write-Host "Downloading Wix 3 Visual Studio extension..."
$filePath = "C:\Install\Votive2022.vsix"
$client = new-object System.Net.WebClient
$client.DownloadFile("https://github.com/wixtoolset/VisualStudioExtension/releases/download/v1.0.0.22/Votive2022.vsix", $filePath)
Write-Host "Installing Wix 3 Visual Studio extension..."
$installerPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
$process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$filePath`"") -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Wix 3 extension install failure"
}

Write-Host "Downloading Wix5 HeatWave Visual Studio extension for VS2022..."
$filePath = "C:\Install\FireGiant.HeatWave.Dev17.vsix"
$client = new-object System.Net.WebClient
$client.DownloadFile("https://marketplace.visualstudio.com/_apis/public/gallery/publishers/FireGiant/vsextensions/FireGiantHeatWaveDev17/latest/vspackage", $filePath)
Write-Host "Installing Wix5 HeatWave Visual Studio extension for VS2022..."
$process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$filePath`"") -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Wix 5 extension install failure"
}
