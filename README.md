Sample project that demonstrates how to automate building of a Windows CI/CD build node Virtual Machine (VM) with Packer and automation scripts.

Based on the GitHub [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer) project with extensive modifications.

## Image build steps

Change `switch_name` in `variables_ws2022.pkvars.hcl` to a switch with internet access.

From an admin command prompt:
```
set PATH=%PATH%;C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
packer build --force --var-file=variables_ws2022.pkvars.hcl hv_windows.pkr.hcl
```

## Prerequisites
* Hyper-V installed and enabled
* [Packer](https://developer.hashicorp.com/packer/install) downloaded with `packer.exe` in PATH
* Windows [Assessment and Deployment Kit (ADK)](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) installed (for `Oscdimg`)

#### Packer initialization
```
packer plugins install github.com/hashicorp/hyperv
packer plugins install github.com/rgl/windows-update
```

## Documentation

### Windows documentation
* Hyper-V [Switch and network adapter choices](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/plan-hyper-v-networking-in-windows-server#switch-and-network-adapter-choices)
* [Installation and configuration for Windows Remote Management](https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management) - uses HTTP port 5985 and HTTPS port 5986. 

### Packer documentation
* HashiCorp [Packer documentation](https://developer.hashicorp.com/packer) ([sources](https://github.com/hashicorp/packer))
* Packer [Unattended Installation for Windows](https://developer.hashicorp.com/packer/guides/automatic-operating-system-installs/autounattend_windows)
* Packer [`winrm`](https://developer.hashicorp.com/packer/docs/communicators/winrm) communicator
* Packer [`powershell`](https://developer.hashicorp.com/packer/docs/provisioners/powershell) provisioner
* Packer [`windows-restart`](https://developer.hashicorp.com/packer/docs/provisioners/windows-restart) provisioner
* Packer [`hyperv`](https://developer.hashicorp.com/packer/integrations/hashicorp/hyperv) plugin ([sources](https://github.com/hashicorp/packer-plugin-hyperv))
* Packer [`rgl/windows-update`](https://github.com/rgl/packer-plugin-windows-update) plugin

### Similar Windows image projects
* GitHub [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer) - starting point for this project
* GitHub [StefanScherer/packer-windows](https://github.com/StefanScherer/packer-windows)
* GitHub [jborean93/packer-windoze](https://github.com/jborean93/packer-windoze)
* GitHub [MattHodge/PackerTemplates](https://github.com/MattHodge/PackerTemplates) - with shutdown samples

## Windows server images
* [Windows Server 2022 download](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022) 21H2- `SERVER_EVAL_x64FRE_en-us.iso` (4.7 GB)
* [Windows Server 2025 download](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025) 24H2 - `26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso` (5.6 GB)

## Amazon Web Services
Query AMI name:
* Command: `aws ec2 describe-images --image-ids <ami-id> --region <region>` (use [Amazon CLI](https://aws.amazon.com/cli/))
