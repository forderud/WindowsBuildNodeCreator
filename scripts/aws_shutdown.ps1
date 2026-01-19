Write-Host "Disable WinRM startup on next boot..."
Set-Service -Name WinRM -StartupType Disabled

Write-Host "Reset admin password..."
& "C:/Program Files/Amazon/EC2Launch/ec2launch" reset

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/sysprep-using-ec2launchv2.html
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2launch-v2-settings.html
Write-Host "Disable RDP, then call sysprep to generalize image..."
& "C:/Program Files/Amazon/EC2Launch/ec2launch.exe" sysprep

Write-Host "Shutting down..."
& shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown
