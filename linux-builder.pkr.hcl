packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source = "github.com/hashicorp/amazon"
    }
  }
}

variable "BUILD_SERVER_URL" { # URL to Jenkins agent, GitLab server or GitHub server
  type    = string
  default = ""
}
variable "BUILDER_SECRET" { # Jenkins builder secret, GitLab runner token or GitHub runner token
  type    = string
  default = ""
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

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 128 # GB
    delete_on_termination = true
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
      "echo Installing podman container runtime...",
      "sudo apt-get install -y podman podman-docker",
    ]
  }

  provisioner "shell" {
    environment_vars = ["BUILD_SERVER_URL=${var.BUILD_SERVER_URL}", "BUILDER_SECRET=${var.BUILDER_SECRET}"]
    script = "Install/InstallCiAgent.sh"
  }
}
