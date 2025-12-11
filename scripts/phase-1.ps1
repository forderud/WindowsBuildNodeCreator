# Main Phase-1 script
# Windows Features, Firewall rules and registry entries,chocolatey

function PrintWindowsVersion {
    $os = Get-WMIObject Win32_OperatingSystem
    Write-Output "Phase 1 [INFO] - $($os.Caption) (version $($os.Version)) found."
}

# Phase 1 - Mandatory generic stuff
Write-Output "Phase 1 [START] - Start of Phase 1"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Import-Module ServerManager

PrintWindowsVersion

Enable-NetFirewallRule -DisplayGroup "Windows Defender Firewall Remote Management" -Verbose

# features and firewall rules common for all Windows Servers
try {
    Install-WindowsFeature NET-Framework-45-Core,Telnet-Client,RSAT-Role-Tools -IncludeManagementTools
    Install-WindowsFeature SNMP-Service,SNMP-WMI-Provider -IncludeManagementTools
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose
    Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Verbose
    Enable-NetFirewallRule -DisplayGroup "Remote Service Management" -Verbose
    Enable-NetFirewallRule -DisplayGroup "Performance Logs and Alerts" -Verbose
    Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Verbose
    Enable-NetFirewallRule -DisplayGroup "Remote Service Management" -Verbose
    Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Verbose
}
catch {
    Write-Output "Phase 1 [ERROR] - setting firewall went wrong"
}

# Terminal services and sysprep registry entries
try {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0 -Verbose -Force
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 0 -Verbose -Force
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Verbose -Force
    Set-ItemProperty -Path 'HKLM:\SYSTEM\Setup\Status\SysprepStatus' -Name 'GeneralizationState' -Value 7 -Verbose -Force
}
catch {
    Write-Output "Phase 1 [ERROR] - setting registry went wrong"
}

# Install chocolatey
Write-Output "Phase 1 [INFO] - installing Chocolatey, attempt $choco_install_count of $choco_install_count_max"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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

Write-Output "Phase 1 [END] - End of Phase 1"
exit 0
