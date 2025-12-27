Based on the GitHub [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer) project with extensive modifications.

## Image build steps

Change `switch_name` in `variables.pkvars.hcl` to a switch with internet access.

From an admin command prompt:
```
set PATH=%PATH%;C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
packer init hv_windows.pkr.hcl
packer build --force --var-file=variables.pkvars.hcl hv_windows.pkr.hcl
```

## Prerequisites
* Hyper-V installed and enabled
* Windows [Assessment and Deployment Kit (ADK)](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) installed (for `Oscdimg`)
