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
  communicator  = "winrm"
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

  user_data_file = "./bootstrap.txt"

  winrm_username = "Administrator"
  winrm_insecure = true
  winrm_use_ssl = true
}

build {
  name    = "learn-packer"
  sources = ["source.amazon-ebs.windows-builder"]

  provisioner "powershell" {
    script = "./prepare.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    script = "./shutdown.ps1"
  }
}
