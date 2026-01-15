:: Stop whitelisting WinRM in firewall
::netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=no

:: Call sysprep to generalize image
"C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /unattend:E:\unattend.xml /quiet /quit

shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown
