Write-Host "Disable WinRM startup on next boot..."
Set-Service -Name WinRM -StartupType Disabled

Write-Host "Reset admin password..."
& 'C:/Program Files/Amazon/EC2Launch/ec2launch' reset

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/sysprep-using-ec2launchv2.html
Write-Host "Make image generic..."
& 'C:/Program Files/Amazon/EC2Launch/ec2launch' sysprep --shutdown
