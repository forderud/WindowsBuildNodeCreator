variable "switch_name" {
  type    = string
  default = ""
}


source "hyperv-iso" "vm" {
  cpus                  = "4"
  memory                = "4096"
  disk_size             = "80000"
  enable_dynamic_memory = "true"
  enable_secure_boot    = false
  generation            = 2
  guest_additions_mode  = "disable"
  skip_export           = true
  switch_name           = "${var.switch_name}"
  temp_path             = "."
  vlan_id               = ""

  vm_name               = "windows-builder"
  output_directory      = "output"

  iso_url               = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
  iso_checksum          = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"

  boot_command          = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait             = "1s"

  cd_files              = ["./files/Autounattend.xml", "./files/bootstrap.ps1"]
  cd_label              = "cidata"

  shutdown_command      = "C:/PackerShutdown.bat"

  communicator          = "winrm"
  winrm_password        = "password"
  winrm_username        = "Administrator"
}

build {
  sources = ["source.hyperv-iso.vm"]

  provisioner "powershell" {
    elevated_password = "password"
    elevated_user     = "Administrator"
    script            = "./scripts/phase-1.ps1"
  }

  provisioner "windows-restart" {
    restart_timeout = "1h"
  }

  provisioner "powershell" {
    elevated_password = "password"
    elevated_user     = "Administrator"
    script            = "./scripts/phase-2.ps1"
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
    destination = "C:\\Windows\\System32\\Sysprep\\unattend.xml"
    source      = "./files/unattend.xml"
  }
  provisioner "file" {
    destination = "C:\\PackerShutdown.bat"
    source      = "./scripts/PackerShutdown.bat"
  }
}
