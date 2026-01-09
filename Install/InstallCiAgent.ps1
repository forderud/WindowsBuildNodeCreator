# stop script on first error
$ErrorActionPreference = "Stop"

# NOTICE: The script expects $Env:BUILD_SERVER_URL and $Env:BUILDER_SECRET to have already been set
# or a CI_PARAMS file to be present.
if (Test-Path "C:\Install\CI_PARAMS" -PathType Leaf) {
    $ciParams = Get-Content -Path "C:\Install\CI_PARAMS"
    $url = $ciParams[0]
    $token = $ciParams[1]
} else {
    $url   = $Env:BUILD_SERVER_URL
    $token = $Env:BUILDER_SECRET
}

Write-Host "CI agent URL: $url"
Write-Host "CI agent token: $token"

if ((-not $url) -or (-not $token)) {
    Write-Host "Skipping CI agent installation due to lack of URL or token."
    exit 0
}

if ($url[-1] -eq "/") {
    # strip trailing "/" from URL if present
    $url = $url.Substring(0, $url.Length-1)
}

function InstallJava {
    Write-Host "Downloading Java JDK 21 (LTS)..."
    $javaMsiName = "jdk-21_windows-x64_bin.msi"
    $javaMsiPath = "C:\Install\"+$javaMsiName
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://download.oracle.com/java/21/latest/"+$javaMsiName, $javaMsiPath)

    Write-Host "Installing Java..."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $javaMsiPath, "/qn", "/norestart" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Java install failure (ExitCode: {0})" -f $process.ExitCode
    }

    Write-Host "Let Java trust the GEHC root CA..."
    & "C:\Program Files\Java\jdk-21\bin\keytool.exe" -import -alias gehealthcarerootca1 -file "C:\Install\gehealthcarerootca1.crt" -keystore "C:\Program Files\Java\jdk-21\lib\security\cacerts" -noprompt
    if ($process.ExitCode -ne 0) {
        throw "Java GEHC root CA 1 failure (ExitCode: {0})" -f $process.ExitCode
    }
    & "C:\Program Files\Java\jdk-21\bin\keytool.exe" -import -alias gehealthcarerootca2 -file "C:\Install\gehealthcarerootca2.crt" -keystore "C:\Program Files\Java\jdk-21\lib\security\cacerts" -noprompt
    if ($process.ExitCode -ne 0) {
        throw "Java GEHC root CA 2 failure (ExitCode: {0})" -f $process.ExitCode
    }
}

function InstallJenkinsAgent {
    Write-Host "Downloading service wrapper..."
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe", "C:\Install\JenkinsAgent.exe")

    Write-Host "Downloading Jenkins agent..."
    $client = new-object System.Net.WebClient
    $urlParts = $url.Split("/")
    $agentUrl = $urlParts[0] + "//" + $urlParts[2] + "/jnlpJars/agent.jar"
    $client.DownloadFile($agentUrl, "C:\Install\agent.jar")

    Write-Host "Creating JenkinsAgent.xml for service wrapper..."
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
    $executable.InnerText = "C:\Program Files\Common Files\Oracle\Java\javapath\java.exe"
    $service.AppendChild($executable)
    # <<arguments>></<arguments>>
    $arguments = $xml.CreateElement("arguments")
    $arguments.InnerText = "-jar C:\Install\agent.jar -jnlpUrl $url -noCertificateCheck -secret $token -workDir C:\Jenkins"
    $service.AppendChild($arguments)
    # <log mode="roll"></log>
    $log = $xml.CreateElement("log")
    $log.SetAttribute("mode", "roll")
    $service.AppendChild($log)
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
    # https://docs.gitlab.com/runner/install/windows.html
    $client = new-object System.Net.WebClient
    $runnerUrl = "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-windows-amd64.exe"
    $client.DownloadFile($runnerUrl, "C:\Install\gitlab-runner.exe")

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


if ($url -like "*gitlab*") {
    # Assume GitLab setup
    InstallGitLabRunner
} else {
    # Assume Jenkins setup
    InstallJava
    InstallJenkinsAgent
}
