# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:BUILD_SERVER_URL and $Env:BUILDER_SECRET to have already been set
$url   = $Env:BUILD_SERVER_URL
$token = $Env:BUILDER_SECRET

Write-Host "CI agent URL: $url"
Write-Host "CI agent token: $token"

if ((-not $url) -or (-not $token)) {
    Write-Host "SKIPPING CI agent installation due to lack of URL or token."
    exit 0
}

if ($url[-1] -eq "/") {
    # strip trailing "/" from URL if present
    $url = $url.Substring(0, $url.Length-1)
}


function InstallJava {
    # Using Amzon Corretto (https://aws.amazon.com/corretto/) instead of Oracle Java
    # this avoids Windows Defender quarantine due to threat EUS:Win32/CustomEnterpriseBlock!cl
    $javaMsiName = "amazon-corretto-17-x64-windows-jdk.msi"
    $javaMsiPath = "C:\Install\"+$javaMsiName
    Write-Host "Downloading Java..."
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://corretto.aws/downloads/latest/"+$javaMsiName, $javaMsiPath)

    Write-Host "Installing Java..."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $javaMsiPath, "/qn", "/norestart" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Java install failure (ExitCode: {0})" -f $process.ExitCode
    }

    $curVer = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\JavaSoft\JDK" -Name "CurrentVersion"
    $javaHome = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\JavaSoft\JDK\$curVer" -Name "JavaHome"

    Write-Host "Let Java trust the GEHC root CA..."
    & "$javaHome\bin\keytool.exe" -import -alias gehealthcarerootca1 -file "C:\Install\gehealthcarerootca1.crt" -cacerts -noprompt -storepass changeit
    if ($process.ExitCode -ne 0) {
        throw "Java GEHC root CA 1 failure (ExitCode: {0})" -f $process.ExitCode
    }
    & "$javaHome\bin\keytool.exe" -import -alias gehealthcarerootca2 -file "C:\Install\gehealthcarerootca2.crt" -cacerts -noprompt -storepass changeit
    if ($process.ExitCode -ne 0) {
        throw "Java GEHC root CA 2 failure (ExitCode: {0})" -f $process.ExitCode
    }

    return $javaHome
}

function InstallJenkinsAgent ($javaHome) {
    Write-Host "Downloading service wrapper..."
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe", "C:\Install\JenkinsAgent.exe")

    Write-Host "Downloading Jenkins agent..."
    $client = new-object System.Net.WebClient
    $urlParts = $url.Split("/")
    $agentUrl = $urlParts[0] + "//" + $urlParts[2] + "/jnlpJars/agent.jar"
    $client.DownloadFile($agentUrl, "C:\Install\agent.jar")

    Write-Host "Creating JenkinsAgent.xml for service wrapper..."
    # Based on https://github.com/winsw/winsw/blob/v3/samples/jenkins.xml
    $xml = New-Object -TypeName System.Xml.XmlDocument
    $service = $xml.CreateElement("service") # root node
    $xml.AppendChild($service)
    # <id></id>
    $id = $xml.CreateElement("id")
    $id.InnerText = "Jenkins Agent"
    $service.AppendChild($id)
    # <name></name>
    $name = $xml.CreateElement("name")
    $name.InnerText = "JenkinsAgent"
    $service.AppendChild($name)
    # <description></description>
    $description = $xml.CreateElement("description")
    $description.InnerText = "Jenkins agent build node"
    $service.AppendChild($description)
    # <executable></executable>
    $executable = $xml.CreateElement("executable")
    $executable.InnerText = "$javaHome\bin\java.exe"
    $service.AppendChild($executable)
    # <arguments></arguments>
    $arguments = $xml.CreateElement("arguments")
    $arguments.InnerText = "-jar C:\Install\agent.jar -jnlpUrl $url -noCertificateCheck -secret $token -workDir C:\Jenkins"
    $service.AppendChild($arguments)
    # <log mode="roll"></log>
    $log = $xml.CreateElement("log")
    $log.SetAttribute("mode", "roll")
    $service.AppendChild($log)
    # <onfailure action="restart" />
    $onfailure = $xml.CreateElement("onfailure")
    $onfailure.SetAttribute("action", "restart")
    $service.AppendChild($onfailure)
    # Save XML file
    $xml.Save("C:\Install\JenkinsAgent.xml")

    Write-Host "Installing Jenkins agent service..."
    & "C:\Install\JenkinsAgent.exe" install
    if ($LastExitCode -ne 0) {
        throw "Jenkins agent service install failure (ExitCode: {0})" -f $LastExitCode
    }

    Write-Host "Starting Jenkins agent service..."
    & "C:\Install\JenkinsAgent.exe" start
    if ($LastExitCode -ne 0) {
        throw "Jenkins agent service startup failure (ExitCode: {0})" -f $LastExitCode
    }
}

function InstallGitLabRunner {
    Write-Host "Downloading GitLab runner..."
    # https://docs.gitlab.com/runner/install/windows/
    $client = new-object System.Net.WebClient
    $runnerUrl = "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-windows-amd64.exe"
    $client.DownloadFile($runnerUrl, "C:\Install\gitlab-runner.exe")

    # Change current-dir to C:\Dev
    Set-Location -Path "C:\Dev"

    Write-Host "Registering GitLab runner..."
    # https://docs.gitlab.com/runner/register/index.html?tab=Windows
    & "C:\Install\gitlab-runner.exe" register --non-interactive --url $url --token $token --executor shell
    if ($LastExitCode -ne 0) {
        throw "GitLab runner register failure (ExitCode: {0})" -f $LastExitCode
    }

    # Change shell from "pwsh" to "powershell" in quasi-INI config file (a bit hacky)
    $cfgFile = $pwd.Path + "\config.toml"
    $cfg = Get-Content $cfgFile
    $cfg = $cfg.Replace('"pwsh"', '"powershell"')
    $cfg | Set-Content $cfgFile

    Write-Host "Installing GitLab runner service..."
    # Service will run using the inbuilt "System" account (recommended)
    & "C:\Install\gitlab-runner.exe" install
    if ($LastExitCode -ne 0) {
        throw "GitLab runner install failure (ExitCode: {0})" -f $LastExitCode
    }

    Write-Host "Starting Jenkins agent service..."
    & "C:\Install\gitlab-runner.exe" start
    if ($LastExitCode -ne 0) {
        throw "GitLab runner startup failure (ExitCode: {0})" -f $LastExitCode
    }
}

function InstallGitHubRunner {
    # https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners
    # download GitHub runner
    $ver = "2.319.1"
    $zipFile = "actions-runner-win-x64-$ver.zip"
    $url = "https://github.com/actions/runner/releases/download/v$ver/$zipFile"
    Invoke-WebRequest -Uri $url -OutFile "C:\Install\$zipFile"
    # extract archive
    Add-Type -AssemblyName System.IO.Compression.FileSystem;
    [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\Install\$zipFile", "C:\Dev")

    # configure and start runner
    Set-Location -Path "C:\Dev"
    & "C:\Dev\config.cmd" --url $url --token $token
    if ($LastExitCode -ne 0) {
        throw "GitHub runner configuration failure (ExitCode: {0})" -f $LastExitCode
    }
    & "C:\Dev\run.cmd"
    if ($LastExitCode -ne 0) {
        throw "GitHub runner startup failure (ExitCode: {0})" -f $LastExitCode
    }
}

# Use C:\Dev as workspace for all CI systems
if (-not (Test-Path "C:\Dev" -PathType Container)) {
    [void](New-Item "C:\Dev" -Type Directory)
}
Write-Host "Excluding C:\Dev from antivirus scans..."
Add-MpPreference -ExclusionPath "C:\Dev"

if ($url -like "*gitlab*") {
    # GitLab setup
    InstallGitLabRunner
} elseif ($url -like "*github*") {
    # GitHub setup
    InstallGitHubRunner
} else {
    # Jenkins setup
    $javaHome = InstallJava
    InstallJenkinsAgent $javaHome
    . C:\Install\CreateCleanJenkinsWorkspaceTask.ps1
}
