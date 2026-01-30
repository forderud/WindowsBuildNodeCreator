# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading Wix toolset..."
$exePath = "C:\Install\wix314.exe"
$client = new-object System.Net.WebClient
$client.DownloadFile("https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe", $exePath)
Write-Host "Installing Wix 3..."
$process = Start-Process -FilePath $exePath -ArgumentList "/install", "/quiet", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Wix 3 install failure (ExitCode: {0})" -f $process.ExitCode
}

# iterate over VS version arguments
for ($i=0; $i -lt $args.Count; $i++) {
    $vsVersion = $args[$i]

    Write-Host "Downloading Wix 3 Visual Studio extension..."
    $installerPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
    if ($vsVersion.Substring(0,2) -eq "16") {
        $vsixPath = "C:\Install\Votive2019.vsix"
        $client = new-object System.Net.WebClient
        $client.DownloadFile("https://github.com/wixtoolset/VisualStudioExtension/releases/download/v1.0.0.22/Votive2019.vsix", $vsixPath)
        $process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$vsixPath`"") -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Votive2019 install failure (ExitCode: {0})" -f $process.ExitCode
        }        
    } elseif ($vsVersion.Substring(0,2) -eq "17") {
        $vsixPath = "C:\Install\Votive2022.vsix"
        $client = new-object System.Net.WebClient
        $client.DownloadFile("https://github.com/wixtoolset/VisualStudioExtension/releases/download/v1.0.0.22/Votive2022.vsix", $vsixPath)
        $process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$vsixPath`"") -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Votive2022 install failure (ExitCode: {0})" -f $process.ExitCode
        }

        Write-Host "Downloading Wix5 HeatWave Visual Studio extension for VS2022..."
        $vsixPath = "C:\Install\FireGiant.HeatWave.Dev17.vsix"
        if ($vsVersion -eq "17/release.ltsc.17.6") {
            # FireGiantHeatWaveDev17 1.0.3 is the last version compatible with VS 17.6
            $heatWaveUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/FireGiant/vsextensions/FireGiantHeatWaveDev17/1.0.3/vspackage"
        } else {
            $heatWaveUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/FireGiant/vsextensions/FireGiantHeatWaveDev17/latest/vspackage"
        }
        $client = new-object System.Net.WebClient
        $client.DownloadFile($heatWaveUrl, $vsixPath)
        Write-Host "Installing Wix5 HeatWave Visual Studio extension for VS2022..."
        $process = Start-Process -FilePath $installerPath -ArgumentList @('/quiet', "`"$vsixPath`"") -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Wix 5 extension install failure (ExitCode: {0})" -f $process.ExitCode
        }
    }
}
