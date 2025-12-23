packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
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
  default = "17/release.ltsc.17.6" # "17/release.ltsc.17.6", "17/release", "16/release.16.7", "16/release"
}
variable "ARTIFACTORY_USER" { # Artifactory username (optional)
  type    = string
  default = ""
}
variable "ARTIFACTORY_PW" { # Artifactory API key from https://eu-artifactory.apps.ge-healthcare.net/ui/user_profile (optional)
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

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "windows-builder" {
  ami_name      = "windows-builder-${local.timestamp}"
  instance_type = "m7i-flex.large" # 2 CPUs, 8GB RAM
  region        = "${var.region}"

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

  user_data_file = "./scripts/bootstrap.txt" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

  communicator  = "winrm"
  winrm_username = "Administrator"
  winrm_insecure = true
  winrm_use_ssl = true
}

build {
  sources = ["source.amazon-ebs.windows-builder"]

  provisioner "file" {
    source      = "./Install"
    destination = "C:\\"
  }

  provisioner "powershell" {
    environment_vars = ["WINRMPASS=${build.Password}"]
    script = "./scripts/prepare.ps1"
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallVisualStudio.ps1 ${var.VISUAL_STUDIO}"]
  }

  provisioner "powershell" {
    inline = ["C:\\Install\\InstallNuGet.ps1 ${var.ARTIFACTORY_USER} ${var.ARTIFACTORY_PW}"]
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
/*
  provisioner "powershell" {
    inline = ["C:\\Install\\InstallWix.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:\\Install\\InstallCiAgent.ps1 ${var.BUILD_SERVER_URL} ${var.BUILDER_SECRET}"]
  }
*/
  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    script = "./scripts/shutdown.ps1"
  }
}
