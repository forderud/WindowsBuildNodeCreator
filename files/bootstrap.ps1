# This script is called from the answerfile

Function ChangeNetworkCategoryToPrivate {
    # Cannot enable WinRM on "Public" network connections
    # https://learn.microsoft.com/nb-no/windows/win32/api/netlistmgr/nn-netlistmgr-inetwork
    $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}'))
    $connections = $networkListManager.GetNetworkConnections()

    $connections |ForEach-Object {
        $category = $_.GetNetwork().GetCategory()
        if ($category -eq 0) { # NLM_NETWORK_CATEGORY_PUBLIC
            $name = $_.GetNetwork().GetName()
            Write-Host "Changing $name category from $category to 1"
            $_.GetNetwork().SetCategory(1) # NLM_NETWORK_CATEGORY_PRIVATE
        }
    }
}
ChangeNetworkCategoryToPrivate

Function Enable-WinRM {
    Write-Host "Enable WinRM"
    # Will set WinRM service to auto-start and enable "Windows Remote Management (HTTP-In)" firewall exception
    winrm quickconfig -quiet -transport:http
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
