packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source = "github.com/hashicorp/amazon"
    }
    windows-update = {
      version = ">= 0.17.1"
      source = "github.com/rgl/windows-update"
    }
    hyperv = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "BUILD_SERVER_URL" { # Jenkins agent URL or GitLab server URL
  type    = string
  default = ""
}
variable "BUILDER_SECRET" { # Jenkins builder secret or GitLab runner token
  type    = string
  default = ""
}
variable "VISUAL_STUDIO" { # Visual Studio version
  type    = string
  default = "17/release" # "17/release.ltsc.17.6", "17/release", "16/release.16.7", "16/release"
}

variable "NUGET_REPO_URL" { # NuGet repo URL (optional)
  type    = string
  default = ""
}
variable "NUGET_REPO_USER" { # NuGet repo username (optional)
  type    = string
  default = ""
}
variable "NUGET_REPO_PW" { # NuGet repo password or API key from https://eu-artifactory.apps.ge-healthcare.net/ui/user_profile (optional)
  type    = string
  default = ""
}

variable "QT_VERSION" {
  type    = string
  default = "qt6.683"
}
variable "QT_INSTALLER_JWT_TOKEN" { # Qt license JWT token from %APPDATA%\\Qt\\qtaccount.ini (optional). The installation will be listed on https://account.qt.io/s/active-installation-list
  type    = string
  default = ""
}

variable "HYPERV_SWITCH" { # Hyper-V switch with internet access
  type    = string
  default = ""
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "hyperv-iso" "windows-builder" {
  cpus                  = "4"
  memory                = "4096"
  disk_size             = "128000" # MB
  generation            = 2
  enable_secure_boot    = false
  enable_tpm            = false
  guest_additions_mode  = "disable"
  skip_export           = true
  switch_name           = "${var.HYPERV_SWITCH}"
  temp_path             = "."
  vlan_id               = ""

  vm_name               = "windows-builder-${local.timestamp}"
  output_directory      = "output"

  # Windows Server 2025 ISO from https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025
  iso_url               = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
  iso_checksum          = "sha256:d0ef4502e350e3c6c53c15b1b3020d38a5ded011bf04998e950720ac8579b23d"

  boot_command          = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait             = "1s"

  cd_files              = ["./Scripts/hyperv/Autounattend.xml", "./Scripts/hyperv/bootstrap.ps1", "./Scripts/hyperv/unattend.xml"]

  shutdown_command      = "\"C:\\Windows\\System32\\Sysprep\\Sysprep.exe\" /generalize /oobe /unattend:E:\\unattend.xml /quiet /shutdown"

  communicator          = "winrm"
  winrm_password        = "password"
  winrm_username        = "Administrator"
}

source "amazon-ebs" "windows-builder" {
  ami_name      = "windows-builder-${local.timestamp}"
  instance_type = "m7i-flex.large" # 2 CPUs, 8GB RAM
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name = "Windows_Server-2025-English-Full-Base*"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 128 # GB
    delete_on_termination = true
  }

  aws_polling {
     max_attempts = 240 # 1 hour (15sec intervals)
  }

  user_data_file = "./Scripts/aws_bootstrap.txt" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

  communicator  = "winrm"
  winrm_username = "Administrator"
  winrm_insecure = true
  winrm_use_ssl = true
}

build {
  sources = [
    "source.hyperv-iso.windows-builder",
    "source.amazon-ebs.windows-builder"
  ]

  provisioner "file" {
    source      = "./Install"
    destination = "C:\\"
  }

  provisioner "powershell" {
    environment_vars = ["WINRMPASS=${build.Password}"]
    script = "./Scripts/prepare.ps1"
  }
  
  provisioner "powershell" {
    only   = ["hyperv-iso.windows-builder"]
    script = "./Scripts/hyperv_prepare.ps1"
  }

  provisioner "windows-update" {
    search_criteria = "AutoSelectOnWebSites=1 and IsInstalled=0" # Important updates
  }

  provisioner "windows-update" {
    search_criteria = "BrowseOnly=0 and IsInstalled=0" # Recommended updates
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallPacker.ps1"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallNuGet.ps1"]
  }

  provisioner "powershell" {
    # Configure NuGet for System account
    inline = [
      "$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument \"-Command `\" `$env:NUGET_REPO_URL='${var.NUGET_REPO_URL}'; `$env:NUGET_REPO_USER='${var.NUGET_REPO_USER}'; `$env:NUGET_REPO_PW='${var.NUGET_REPO_PW}'; C:\\Install\\ConfigureNuGet.ps1 `\" \"",
      "Register-ScheduledTask -Action $action -User \"System\" -TaskName \"NuGet configure\" -Description \"Configure NuGet package sources\"",
      "Start-ScheduledTask -TaskName \"NuGet configure\"",
      #"Unregister-ScheduledTask -TaskName \"NuGet configure\" -Confirm:$false"
    ]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallVisualStudio.ps1 ${var.VISUAL_STUDIO}"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallWix.ps1 ${var.VISUAL_STUDIO}"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallPython.ps1"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallCMake.ps1"]
  }

  provisioner "powershell" {
    environment_vars = ["QT_INSTALLER_JWT_TOKEN=${var.QT_INSTALLER_JWT_TOKEN}"]
    inline = ["C:\\Install\\InstallQt.ps1 ${var.QT_VERSION}"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallGit.ps1"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallSvn.ps1"]
  }

/*
  provisioner "powershell" {
    inline = ["C:\\Install\\InstallDocker.ps1"]
  }
*/

  provisioner "powershell" {
    environment_vars = ["BUILD_SERVER_URL=${var.BUILD_SERVER_URL}", "BUILDER_SECRET=${var.BUILDER_SECRET}"]
    inline = ["C:\\Install\\InstallCiAgent.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
      script = "./Scripts/preshutdown.ps1"
  }

  provisioner "windows-shell" {
    only   = ["amazon-ebs.windows-builder"]
    inline = [
      # Reset admin password
      "\"C:\\Program Files\\Amazon\\EC2Launch\\ec2launch.exe\" reset",

      # Call sysprep to generalize image
      #   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/sysprep-using-ec2launchv2.html
      #   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2launch-v2-settings.html
      "\"C:\\Program Files\\Amazon\\EC2Launch\\ec2launch.exe\" sysprep"
    ]
  }
}
