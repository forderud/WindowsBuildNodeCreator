packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "linux-builder" {
  ami_name      = "linux-builder-${local.timestamp}"
  instance_type = "m7i-flex.large" # 2 CPUs, 8GB RAM
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.linux-builder"
  ]
  
  provisioner "shell" {
    inline = [
      "sleep 10",
      "sudo apt update -y",
    ]
  }
}
