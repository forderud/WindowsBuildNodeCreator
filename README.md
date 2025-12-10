Sample project that demonstrates how to automate building of a Windows CI/CD node Virtual Machime (VM) with Packer and automation scripts.

Based on the GitHub [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer) project with extensive modifications.

## Image build steps

Change `switch_name` in `variables_windows_server_2022_std.pkvars.hcl` to a switch with internet access.

Image build steps:
```
set PATH=%PATH%;C:\Dev;C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
packer build --force --var-file=variables_windows_server_2022_std.pkvars.hcl hv_windows.pkr.hcl
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

### Hyper-V documentation
* Hyper-V [Switch and network adapter choices](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/plan-hyper-v-networking-in-windows-server#switch-and-network-adapter-choices).
* [Create NAT Rules for the Hyper-V NAT Virtual Switch](https://petri.com/create-nat-rules-hyper-v-nat-virtual-switch/) - describes [`Add-NetNatStaticMapping`](https://learn.microsoft.com/en-us/powershell/module/netnat/add-netnatstaticmapping)

### Packer documentation
* HashiCorp [Packer documentation](https://developer.hashicorp.com/packer) ([sources](https://github.com/hashicorp/packer))
* Packer [Unattended Installation for Windows](https://developer.hashicorp.com/packer/guides/automatic-operating-system-installs/autounattend_windows)
* Packer [`winrm`](https://developer.hashicorp.com/packer/docs/communicators/winrm) communicator
* Packer [`powershell`](https://developer.hashicorp.com/packer/docs/provisioners/powershell) provisioner
* Packer [`windows-restart`](https://developer.hashicorp.com/packer/docs/provisioners/windows-restart) provisioner
* Packer [`hyperv`](https://developer.hashicorp.com/packer/integrations/hashicorp/hyperv) plugin ([sources](https://github.com/hashicorp/packer-plugin-hyperv))
* Packer [`rgl/windows-update`](https://github.com/rgl/packer-plugin-windows-update) plugin

### Other template projects
* GitHub [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer) templates
* GitHub [StefanScherer/packer-windows](https://github.com/StefanScherer/packer-windows) templates
* GitHub [jborean93/packer-windoze](https://github.com/jborean93/packer-windoze) templates
* GitHub [MattHodge/PackerTemplates](https://github.com/MattHodge/PackerTemplates) - with shutdown samples

## Windows server images
* [Windows Server 2022 download](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022) 21H2- `SERVER_EVAL_x64FRE_en-us.iso` (4.7 GB)
* [Windows Server 2025 download](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025) 24H2 - `26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso` (5.6 GB)
