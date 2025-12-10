::netsh advfirewall firewall set rule name="WinRM-HTTP" new action=block

::C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /unattend:C:\Windows\System32\Sysprep\unattend.xml /quiet /shutdown

shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown
::pause
