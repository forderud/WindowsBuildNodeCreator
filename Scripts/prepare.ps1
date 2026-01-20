$ver = $PSVersionTable.BuildVersion
Write-Host "Windows OS build: $ver"

Write-Host "PACKER_BUILD_NAME:" $Env:PACKER_BUILD_NAME

Write-Host "Temporary Administrator password: $Env:WINRMPASS"

Write-Host "Install GEHC Root Certificates..."
certutil.exe -addstore -f "root" C:\Install\gehealthcarerootca1.crt
certutil.exe -addstore -f "root" C:\Install\gehealthcarerootca2.crt

Write-Host "Enable crash dump collection to %LOCALAPPDATA%\CrashDumps ..."
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps"
