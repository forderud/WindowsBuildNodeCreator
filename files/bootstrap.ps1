# This script is called from the answerfile

Function Enable-WinRM {
    Write-Host "Enable WinRM"
    # Will set WinRM service to auto-start and enable "Windows Remote Management (HTTP-In)" firewall exception
    winrm quickconfig -transport:http -force
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
    winrm set winrm/config/winrs '@{MaxProcessesPerShell="0"}'
    winrm set winrm/config/winrs '@{MaxShellsPerUser="0"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/client/auth '@{Basic="true"}'
}
Enable-WinRM

# Disable pasword expiry for Administrator account
Get-WmiObject -Class Win32_UserAccount -Filter "name = 'Administrator'" | Set-WmiInstance -Arguments @{PasswordExpires = 0}
