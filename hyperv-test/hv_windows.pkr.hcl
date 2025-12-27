packer {
  required_plugins {
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

variable "switch_name" {
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
  enable_dynamic_memory = "true"
  enable_secure_boot    = false
  generation            = 2
  guest_additions_mode  = "disable"
  skip_export           = true
  switch_name           = "${var.switch_name}"
  temp_path             = "."
  vlan_id               = ""

  vm_name               = "windows-builder-${local.timestamp}"
  output_directory      = "output"

  # Windows Server 2025 ISO from https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025
  iso_url               = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
  iso_checksum          = "sha256:d0ef4502e350e3c6c53c15b1b3020d38a5ded011bf04998e950720ac8579b23d"

  boot_command          = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait             = "1s"

  cd_files              = ["./files/Autounattend.xml", "./files/bootstrap.ps1"]
  cd_label              = "cidata"

  shutdown_command      = "C:/hyperv_shutdown.bat"

  communicator          = "winrm"
  winrm_password        = "password"
  winrm_username        = "Administrator"
}

build {
  sources = ["source.hyperv-iso.windows-builder"]

  provisioner "powershell" {
    elevated_password = "password"
    elevated_user     = "Administrator"
    script            = "./scripts/phase-1.ps1"
  }

  provisioner "windows-restart" {
    restart_timeout = "1h"
  }

  provisioner "windows-restart" {
    pause_before          = "1m0s"
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
    restart_timeout       = "2h"
  }

/*
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    update_limit    = 10
  }

  provisioner "windows-restart" {
    restart_timeout = "1h"
  }

  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    update_limit    = 10
  }

  provisioner "windows-restart" {
    restart_timeout = "1h"
  }
*/

  provisioner "file" {
    only        = ["hyperv-iso.windows-builder"]
    destination = "C:\\Windows\\System32\\Sysprep\\unattend.xml"
    source      = "./files/unattend.xml"
  }
  provisioner "file" {
    only        = ["hyperv-iso.windows-builder"]
    destination = "C:\\hyperv_shutdown.bat"
    source      = "./scripts/hyperv_shutdown.bat"
  }
}
