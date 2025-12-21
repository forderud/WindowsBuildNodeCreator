$ver = $PSVersionTable.BuildVersion
Write-Host "Windows OS build: $ver"

Write-Host "PACKER_BUILD_NAME:" $Env:PACKER_BUILD_NAME
