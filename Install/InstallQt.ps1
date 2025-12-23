# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:QT_INSTALLER_JWT_TOKEN to have already been set

# Install Qt maintenance tool first
& "C:\Install\qt-online-installer.exe" --root C:\Qt --accept-licenses --default-answer --confirm-command --no-default-installations install qt.tools.maintenance
if ($LastExitCode -ne 0) {
    throw "Qt online install failure"
}

# iterate over Qt version arguments
for ($i=0; $i -lt $args.Count; $i++) {
    $qtVersion = $args[$i]

    # Install Qt with ActiveQt, Qt3D & WebEngine
    # The installation will be listed on https://account.qt.io/s/active-installation-list
    # Doc: https://doc.qt.io/qt-6/get-and-install-qt-cli.html
    $modules = @()
    if ($qtVersion.Split(".")[1] -lt "680") {
        $modules += "qt.$qtVersion.win64_msvc2019_64"
        $modules += "qt.$qtVersion.addons.qtwebengine"
        $msvcVer = "msvc2019_64"
    } else {
        $modules += "qt.$qtVersion.win64_msvc2022_64"
        $modules += "extensions.qtwebengine." + $qtVersion.Split(".")[1]
        $msvcVer = "msvc2022_64"
    }
    $modules += "qt.$qtVersion.addons.qtactiveqt", "qt.$qtVersion.addons.qt3d"

    & "C:\Qt\MaintenanceTool.exe" --accept-licenses --default-answer --confirm-command install @modules
    if ($LastExitCode -ne 0) {
        throw "Qt install failure"
    }
}

# Let QT_ROOT_64 point to the Qt SDK path for the last argument
$ver = $qtVersion.Split(".")[1] # from "qt5.5152" to "5152"
$ver = $ver[0]+"."+$ver.substring(1, $ver.length-2)+"."+$ver[-1] # from "5152" to 5.15.2)
setx.exe QT_ROOT_64 C:\Qt\$ver\$msvcVer /M
