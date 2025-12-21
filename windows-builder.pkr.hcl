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
  instance_type = "t3.small" # 2 CPUs, 2GB RAM
  region        = "${var.region}"

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2025-English-Full-Base*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
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
    script = "./scripts/prepare.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    script = "./scripts/shutdown.ps1"
  }
}
