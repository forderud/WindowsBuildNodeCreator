# stop script on first error
$ErrorActionPreference = "Stop"

# Download Python 3.12
$client = new-object System.Net.WebClient
$client.DownloadFile("https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe", "C:\Install\python-amd64.exe")

# Install Python
$process = Start-Process -FilePath "C:\Install\python-amd64.exe" -ArgumentList "/quiet", "InstallAllUsers=1" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Python installation failure"
}

# Enable truststore feature for GEHC CA usage
# Doc: https://pip.pypa.io/en/stable/topics/https-certificates/
& "C:\Program Files\Python312\Scripts\pip.exe" config set global.use-feature truststore
if ($LastExitCode -ne 0) {
    throw "pip truststore failure"
}

# install python packages
& "C:\Program Files\Python312\Scripts\pip.exe" install comtypes numpy matplotlib pywin32
if ($LastExitCode -ne 0) {
    throw "pip install failure"
}
