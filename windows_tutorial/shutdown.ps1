Write-Host "Disable WinRM startup on next boot..."
Set-Service -Name WinRM -StartupType Disabled

Write-Host "Reset admin password..."
& 'C:/Program Files/Amazon/EC2Launch/ec2launch' reset

Write-Host "Make image generic..."
& 'C:/Program Files/Amazon/EC2Launch/ec2launch' sysprep --shutdown
