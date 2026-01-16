# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Appx cleanup before sysprep..."

# Remove per-user Microsoft Edge installations to prevent sysprep failures
# DOC: https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/sysprep-fails-remove-or-update-store-apps
$packages = Get-AppxPackage -Name "Microsoft.MicrosoftEdge.*"
foreach ($package in $packages) {
    Write-Host("Removing {0}..." -f $package.Name)

    Remove-AppxPackage -Package $package.PackageFullName

    # Fails with "Remove-AppxProvisionedPackage : The system cannot find the file specified."
    #Remove-AppxProvisionedPackage -Online -PackageName $package.PackageFullName
}

Write-Host "Calling sysprep..."
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /unattend:E:\unattend.xml /quiet /quit
if ($LastExitCode -ne 0) {
    Write-Host "sysprep error (ExitCode: {0})" -f $LastExitCode
    sleep 1800 # sleep 30min to give time for interactive debugging
    throw "sysprep error (ExitCode: {0})" -f $LastExitCode
}

Write-Host "[done]"
