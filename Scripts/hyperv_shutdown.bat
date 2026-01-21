:: Stop whitelisting WinRM in firewall
::netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=no

:: Call sysprep to generalize image
"C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /unattend:E:\unattend.xml /quiet /shutdown
