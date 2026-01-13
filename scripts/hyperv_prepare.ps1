Write-Output "Enable Remote Desktop Protocol (RDP).."
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0 -Verbose -Force

Write-Output "Setting high performance power plan..."
powercfg.exe /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
