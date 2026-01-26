Project to **automate building of Windows CI/CD build node images** using Packer automation scripts. The images can either be built on Amazon AWS or locally using Hyper-V.

### Installed SW
* [CI agent](Install/InstallCiAgent.ps1) - Jenkins or GitLab CI (optional)
* [CMake](Install/InstallCMake.ps1)
* [Docker](Install/InstallDocker.ps1)
* [Git](Install/InstallGit.ps1)
* [NuGet](Install/InstallNuGet.ps1)
* [Packer](Install/InstallPacker.ps1) for self-hosting
* [Python](Install/InstallPython.ps1)
* [Qt](Install/InstallQt.ps1) (optional, version configurable)
* [Svn](Install/InstallSvn.ps1)
* [Visual Studio](Install/InstallVisualStudio.ps1) with C++, .Net workloads and WDK (version configurable)
* [Wix and HeatWave](Install/InstallWix.ps1) for MSI packaging

## AWS build instructions
Instructions to build a new Amazon AMI image:
```
packer init windows-builder.pkr.hcl
packer build -only=amazon-ebs.windows-builder --var-file=variables.pkvars.hcl windows-builder.pkr.hcl
```

Example `variables.pkvars.hcl` file:
```
BUILD_SERVER_URL="https://gitlab.kitware.com"
BUILDER_SECRET=""
VISUAL_STUDIO="17/release.ltsc.17.6"
NUGET_REPO_USER=""
NUGET_REPO_PW=""
NUGET_REPO_URL=""
QT_VERSION="qt6.683"
QT_INSTALLER_JWT_TOKEN=""
```

### AWS prerequisites
The `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` env.vars. set as described in the Amazon packer integration. You'll find these by logging in to http://aws.amazon.com/ and afterwards opening "Security Credentials" for your account.

It's possible to use a [AWS Free Tier](https://aws.amazon.com/free/) account with this project.

### RDP connection
Steps to connect with RDP to the VM during packer build:
* Edit the VM "Security group" and add an inbound "RDP" firewall rule.
* Use the VM "Public DNS" name to connect to the VM with the remote desktop client.
* Use `Administrator` as username and the temporary WinRM password from the packer build log.

### AMI boot parameters
It's possible to run arbitrary scripts on first boot with ["user data"](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) when creating a new Amazon VM instance based on a AMI image. This can be useful for deferred configuration of parameters that differ between VM instances.

Example "user data" for deferred NuGet and CI agent configuration:
```
<powershell>
  $Env:BUILD_SERVER_URL = "..."
  $Env:BUILDER_SECRET= "..."
  . C:\Install\InstallCiAgent.ps1
</powershell>
```

## Hyper-V build instructions
Instructions to build a local Hyper-V image:

Edit `variables.pkvars.hcl` as in AWS instructions above. In addition, set `HYPERV_SWITCH` to a switch with internet access.

From an admin command prompt:
```
set PATH=%PATH%;C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
packer init windows-builder.pkr.hcl
packer build -only=hyperv-iso.windows-builder --var-file=variables.pkvars.hcl windows-builder.pkr.hcl
```

### Hyper-V prerequisites
* Hyper-V installed and enabled
* Windows [Assessment and Deployment Kit (ADK)](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) installed

## Generic prerequisites
* [Packer](https://developer.hashicorp.com/packer/install) downloaded with `packer.exe` in `PATH`

### Debugging build problems
Verbose build output: `set PACKER_LOG=1`

## Documentation

### Windows documentation
* Hyper-V [Switch and network adapter choices](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/plan-hyper-v-networking-in-windows-server#switch-and-network-adapter-choices)
* [Manage Windows Server on Amazon EC2 by using Windows Admin Center](https://learn.microsoft.com/en-us/windows-server/manage/windows-admin-center/use/manage-aws-machines) - AWS WinRM firewall instructions
* [Installation and configuration for Windows Remote Management](https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management) - WinRM uses HTTP port 5985 and HTTPS port 5986. 

### Packer documentation
* [Packer documentation](https://developer.hashicorp.com/packer) ([sources](https://github.com/hashicorp/packer))
* Packer [Unattended Installation for Windows](https://developer.hashicorp.com/packer/guides/automatic-operating-system-installs/autounattend_windows)
* Packer [`winrm`](https://developer.hashicorp.com/packer/docs/communicators/winrm) communicator
* Packer [`powershell`](https://developer.hashicorp.com/packer/docs/provisioners/powershell) provisioner
* Packer [`windows-restart`](https://developer.hashicorp.com/packer/docs/provisioners/windows-restart) provisioner
* AWS [Build a Windows image](https://developer.hashicorp.com/packer/tutorials/cloud-production/aws-windows-image) tutorial
* [learn-packer-windows-ami](https://github.com/hashicorp-education/learn-packer-windows-ami) sample
* Packer [`rgl/windows-update`](https://github.com/rgl/packer-plugin-windows-update) plugin
* Packer [Amazon integration](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon) - mentions `%USERPROFILE%.aws\credentials` ([sources](https://github.com/hashicorp/packer-plugin-amazon))
* Packer [Hyper-V integration](https://developer.hashicorp.com/packer/integrations/hashicorp/hyperv) ([sources](https://github.com/hashicorp/packer-plugin-hyperv))

### Related Windows image projects
* GitHub [Actions runner windows images](https://github.com/actions/runner-images/tree/main/images/windows)
* runs-on [GitHub Actions Runner images for AWS](https://github.com/runs-on/runner-images-for-aws)

## Windows server images
* Microsoft [Windows Server 2025 download](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025) 24H2 - `26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso` (September 10, 2024, 5.6 GB)
* Microsoft [Windows Server 2022 download](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022) 21H2- `SERVER_EVAL_x64FRE_en-us.iso` (4.7 GB)
* Amazon [Windows AMIs](https://aws.amazon.com/windows/resources/amis/) - named `Windows_Server-2025-English-Core-Base-<date>`(updated monthly)
