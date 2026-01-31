# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:QT_INSTALLER_JWT_TOKEN to have already been set
if (-not $Env:QT_INSTALLER_JWT_TOKEN) {
    Write-Host "SKIPPING Qt installation due to lack of license."
    exit 0
}

if (-not (Test-Path "C:\Qt" -PathType Container)) {
    # DOC: https://doc.qt.io/qt-6/get-and-install-qt-cli.html
    Write-Host "Downloading Qt online installer..."
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://download.qt.io/official_releases/online_installers/qt-online-installer-windows-x64-online.exe","C:\Install\qt-online-installer.exe")

    Write-Host "Installing Qt maintenance tool..."
    & "C:\Install\qt-online-installer.exe" --root C:\Qt --accept-licenses --default-answer --confirm-command --no-default-installations install qt.tools.maintenance
    if ($LastExitCode -ne 0) {
        throw "Qt online install failure (ExitCode: {0})" -f $LastExitCode
    }
}

# iterate over Qt version arguments
for ($i=0; $i -lt $args.Count; $i++) {
    $qtVersion = $args[$i]

    # Install Qt with ActiveQt, Qt3D & WebEngine
    # The installation will be listed on https://account.qt.io/s/active-installation-list
    # Doc: https://doc.qt.io/qt-6/get-and-install-qt-cli.html
    $modules = @()
    if ($qtVersion.Split(".")[0] -eq "qt5") {
        # Qt 5
        $modules += "qt.$qtVersion.win64_msvc2019_64" # includes ActiveQt & Qt3D
        #$modules += "qt.$qtVersion.qtwebengine"
        $modules += "qt.$qtVersion.qtcharts"
        $msvcVer = "msvc2019_64"
    } else {
        # Qt 6
        if ($qtVersion.Split(".")[1] -lt "680") {
            # Qt 6.0-6.7
            $modules += "qt.$qtVersion.win64_msvc2019_64"
            $modules += "qt.$qtVersion.addons.qtwebengine"
            $msvcVer = "msvc2019_64"
        } else {
            # Qt 6.8-
            $modules += "qt.$qtVersion.win64_msvc2022_64"
            $modules += "extensions.qtwebengine." + $qtVersion.Split(".")[1] + ".win64_msvc2022_64"
            $msvcVer = "msvc2022_64"
        }

        $modules += "qt.$qtVersion.addons.qtactiveqt"
        $modules += "qt.$qtVersion.addons.qtcharts"
        $modules += "qt.$qtVersion.addons.qt3d"
    }

    Write-Host "Installing $modules..."
    & "C:\Qt\MaintenanceTool.exe" --accept-licenses --default-answer --confirm-command install @modules
    if ($LastExitCode -ne 0) {
        #Write-Host("Qt install failure (ExitCode: {0})" -f $LastExitCode)
        #sleep 1800 # sleep 30min to give time for interactive debugging
        throw "Qt install failure (ExitCode: {0})" -f $LastExitCode
    }
}

if ($qtVersion) {
    Write-Host "Let QT_ROOT_64 point to the Qt SDK path for the last argument"
    $ver = $qtVersion.Split(".")[1] # from "qt5.5152" to "5152"
    $ver = $ver[0]+"."+$ver.substring(1, $ver.length-2)+"."+$ver[-1] # from "5152" to 5.15.2)
    setx.exe QT_ROOT_64 C:\Qt\$ver\$msvcVer /M
}
