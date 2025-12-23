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

  provisioner "powershell" {
      inline = ["C:\\Install\\InstallNuGet.ps1"]
  }

  provisioner "powershell" {
      inline = ["C:\\Install\\InstallPython.ps1"]
  }

  provisioner "powershell" {
      inline = ["C:\\Install\\InstallCMake.ps1"]
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    script = "./scripts/shutdown.ps1"
  }
}
