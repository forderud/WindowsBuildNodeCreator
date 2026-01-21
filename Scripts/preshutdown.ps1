# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Appx cleanup before sysprep..."

# Remove per-user Microsoft Edge installations to prevent sysprep failures
# DOC: https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/sysprep-fails-remove-or-update-store-apps
$packages = Get-AppxPackage -Name "Microsoft.MicrosoftEdge.*"
foreach ($package in $packages) {
    Write-Host("* Removing {0}..." -f $package.Name)
    Remove-AppxPackage -Package $package.PackageFullName
}
# Remove per-user TortoiseSVN installations to prevent sysprep failures
$packages = Get-AppxPackage | Where PublisherId -eq yyj3t4bx8qhke # Stefan Kueng
foreach ($package in $packages) {
    Write-Host("* Removing {0}..." -f $package.Name)
    Remove-AppxPackage -Package $package.PackageFullName
}

Write-Host "Disable WinRM startup on next boot..."
Set-Service -Name WinRM -StartupType Disabled

# Stop whitelisting WinRM in firewall
# & netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=no

