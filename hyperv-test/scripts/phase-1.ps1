# Main Phase-1 script
# Windows Features, Firewall rules

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

Write-Output "[INFO] - Setting high performance power plan"
powercfg.exe /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

Write-Output "Phase 1 [END] - End of Phase 1"
exit 0
