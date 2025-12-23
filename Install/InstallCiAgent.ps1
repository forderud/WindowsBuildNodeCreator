# stop script on first error
$ErrorActionPreference = "Stop"

# require CI_PARAMS file
$ciParams = Get-Content -Path "C:\Install\CI_PARAMS"

if ($ciParams[0][-1] -eq "/") {
    # strip trailing "/" from URL if present
    $ciParams[0] = $ciParams[0].Substring(0, $ciParams[0].Length-1)
}

function InstallJava {
    # Download Java JDK 21 (LTS)
    $javaMsiName = "jdk-21_windows-x64_bin.msi"
    $javaMsiPath = "C:\Install\"+$javaMsiName
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://download.oracle.com/java/21/latest/"+$javaMsiName, $javaMsiPath)

    # Install Java
    $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", $javaMsiPath, "/qn", "/norestart" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Java install failure"
    }

    # Let Java trust the GE root CA
    & "C:\Program Files\Java\jdk-21\bin\keytool.exe" -import -alias gehealthcarerootca1 -file "C:\Install\gehealthcarerootca1.crt" -keystore "C:\Program Files\Java\jdk-21\lib\security\cacerts" -noprompt
    if ($process.ExitCode -ne 0) {
        throw "Java GEHC root CA 1 failure"
    }
    & "C:\Program Files\Java\jdk-21\bin\keytool.exe" -import -alias gehealthcarerootca2 -file "C:\Install\gehealthcarerootca2.crt" -keystore "C:\Program Files\Java\jdk-21\lib\security\cacerts" -noprompt
    if ($process.ExitCode -ne 0) {
        throw "Java GEHC root CA 2 failure"
    }
}

function InstallJenkinsAgent {
    # Download service wrapper
    $client = new-object System.Net.WebClient
    $client.DownloadFile("https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe","C:\Install\JenkinsAgent.exe")

    # Download Jenkins agent
    $client = new-object System.Net.WebClient
    $urlParts = $ciParams[0].Split("/")
    $agentUrl = $urlParts[0] + "//" + $urlParts[2] + "/jnlpJars/agent.jar"
    $client.DownloadFile($agentUrl,"C:\Install\agent.jar")

    # Create JenkinsAgent.xml for service wrapper
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
    $arguments.InnerText = "-jar C:\Install\agent.jar -jnlpUrl $($ciParams[0]) -noCertificateCheck -secret $($ciParams[1]) -workDir C:\Jenkins"
    $service.AppendChild($arguments)
    # <log mode="roll"></log>
    $log = $xml.CreateElement("log")
    $log.SetAttribute("mode", "roll")
    $service.AppendChild($log)
    # Save XML file
    $xml.Save("C:\Install\JenkinsAgent.xml")

    # Install Jenkins agent service
    & "C:\Install\JenkinsAgent.exe" install
    if ($LastExitCode -ne 0) {
        throw "Jenkins agent service install failure"
    }

    # Start Jenkins agent service
    & "C:\Install\JenkinsAgent.exe" start
    if ($LastExitCode -ne 0) {
        throw "Jenkins agent service startup failure"
    }
}

function InstallGitLabRunner {
    # Download GitLab runner
    # https://docs.gitlab.com/runner/install/windows.html
    $client = new-object System.Net.WebClient
    $url = "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-windows-amd64.exe"
    $client.DownloadFile($url,"C:\Install\gitlab-runner.exe")

    # Register GitLab runner
    # https://docs.gitlab.com/runner/register/index.html?tab=Windows
    & "C:\Install\gitlab-runner.exe" register --non-interactive --url $ciParams[0] --token $ciParams[1] --executor shell
    if ($LastExitCode -ne 0) {
        throw "GitLab runner register failure"
    }

    # Change shell from "pwsh" to "powershell" in quasi-INI config file (a bit hacky)
    $cfgFile = $pwd.Path + "\config.toml"
    $cfg = Get-Content $cfgFile
    $cfg = $cfg.Replace('"pwsh"', '"powershell"')
    $cfg | Set-Content $cfgFile

    # Install GitLab runner service
    & "C:\Install\gitlab-runner.exe" install
    if ($LastExitCode -ne 0) {
        throw "GitLab runner install failure"
    }

    # Start Jenkins agent service
    & "C:\Install\gitlab-runner.exe" start
    if ($LastExitCode -ne 0) {
        throw "GitLab runner startup failure"
    }
}


if ($ciParams[0] -eq "https://gitlab.apps.ge-healthcare.net") {
    # Assume GitLab setup
    InstallGitLabRunner
} else {
    # Assume Jenkins setup
    InstallJava
    InstallJenkinsAgent
}
