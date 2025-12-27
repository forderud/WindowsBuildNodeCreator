# Main Phase-1 script
# Windows Features, Firewall rules and registry entries,chocolatey

function PrintWindowsVersion {
    $os = Get-WMIObject Win32_OperatingSystem
    Write-Output "Phase 1 [INFO] - $($os.Caption) (version $($os.Version)) found."
}

# Phase 1 - Mandatory generic stuff
Write-Output "Phase 1 [START] - Start of Phase 1"
Import-Module ServerManager

PrintWindowsVersion

# Enable Remote Desktop Protocol (RDP)
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0 -Verbose -Force

# Install chocolatey
Write-Output "Phase 1 [INFO] - installing Chocolatey, attempt $choco_install_count of $choco_install_count_max"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
Write-Output "Phase 1 [INFO] - installing Chocolatey exit code is: $LASTEXITCODE"
if ($LASTEXITCODE -ne 0) {
    Write-Output "Phase 1 [ERROR] - Chocolatey install problem, critical, exiting"
    exit (1)
}

#Remove 260 Character Path Limit
if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem') {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -name "LongPathsEnabled" -Value 1 -Verbose -Force
}

Write-Output "[INFO] - Setting high performance power plan"
powercfg.exe /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

Write-Output "Phase 1 [END] - End of Phase 1"
exit 0
