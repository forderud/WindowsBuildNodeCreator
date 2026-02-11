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
variable "ARTIFACTORY_TOKEN" { # Artifactory authentication token
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
    script = "Install/InstallCiAgent.sh"
  }

  provisioner "shell" {
    inline = [
      "echo Configuring Artifactory authentication token for gitlab-runner account...",
      "sudo -u gitlab-runner mkdir /home/gitlab-runner/.ssh",
      "echo ${var.ARTIFACTORY_TOKEN} | sudo -u gitlab-runner tee /home/gitlab-runner/.ssh/artifactory_identity_token",
    ]
  }

/*
  provisioner "shell" {
    # This step needs to be done on first boot of a new VM
    inline = [
      "echo Registering GitLab runner...",
      "sudo gitlab-runner register --non-interactive --url ${var.BUILD_SERVER_URL} --token ${var.BUILDER_SECRET} --executor \"docker\" --docker-image alpine:latest --description \"docker-runner\"",
      # Change 'volumes = ["/cache"]' lines to 'volumes = ["/cache", "/home/gitlab-runner/.ssh:/root/.ssh:ro"]' to expose Artifactory token to containers
      "sed -i 's/volumes = \["\/cache"/volumes = \["\/cache", "\/home\/gitlab-runner\/.ssh:\/root\/.ssh:ro"/' /etc/gitlab-runner/config.toml",
    ]
  }
*/
}
