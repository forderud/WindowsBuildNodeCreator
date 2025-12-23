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

variable "BUILD_SERVER_URL" {
  type    = string
  default = ""
}
variable "BUILDER_SECRET" {
  type    = string
  default = ""
}
variable "ARTIFACTORY_USER" {
  type    = string
  default = ""
}
variable "ARTIFACTORY_PW" {
  type    = string
  default = ""
}
variable "QT_INSTALLER_JWT_TOKEN" {
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
    volume_size = 64 # GB
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
      inline = ["C:\\Install\\InstallVisualStudio.ps1 17/release.ltsc.17.6"]
  }
/*
  provisioner "powershell" {
      inline = ["C:\\Install\\InstallNuGet.ps1 ${var.ARTIFACTORY_USER} ${var.ARTIFACTORY_PW}"]
  }
*/
  provisioner "powershell" {
      inline = ["C:\\Install\\InstallPython.ps1"]
  }

  provisioner "powershell" {
      inline = ["C:\\Install\\InstallCMake.ps1"]
  }
/*
  provisioner "powershell" {
      inline = ["C:\\Install\\InstallQt.ps1 qt6.683 ${var.QT_INSTALLER_JWT_TOKEN}"]
  }
*/
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
