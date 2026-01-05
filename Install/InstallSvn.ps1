# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Downloading TortoiseSVN..."
$client = new-object System.Net.WebClient
$msiPath = "C:\Install\TortoiseSVN.msi"
$client.DownloadFile("https://sourceforge.net/projects/tortoisesvn/files/1.14.9/Application/TortoiseSVN-1.14.9.29743-x64-svn-1.14.5.msi",$msiPath)

Write-Host "Installing TortoiseSVN..."
# Pass ADDLOCAL=ALL to also install svn.exe and add it to PATH
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $msiPath, "/qn", "/norestart", "ADDLOCAL=ALL" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "TortoiseSVN install failure (ExitCode: {0})" -f $process.ExitCode
}
