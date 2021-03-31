# Creating a Cisco NSO VM image, mainly for CML2

variable "cpus" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "4G"
}

variable "install_directory" {
  type    = string
  default = "/pkgs/nso-install"
}

variable "iso_checksum" {
  type    = string
//  default = "sha256:075cbdf6b7d10968a903befb364f1f98620eccb32a9f988250d3b97170e29356"
}

variable "iso_url" {
  type    = string
  default = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "memory" {
  type    = string
  default = "2048M"
}

variable "nso_java_opts" {
  type    = string
  default = "-Xmx2G -Xms1G"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "update_os" {
  type    = string
  default = "true"
}

variable "nso_version" {
  type    = string
  default = "5.5"
}

variable "ned_ios" {
  type    = string
  default = "ncs-5.5-cisco-ios-6.69.1"
}

variable "ned_ios_id" {
  type    = string
  default = "cisco-ios-cli-6.69"
}

variable "ned_iosxr" {
  type    = string
  default = "ncs-5.5-cisco-iosxr-7.33.1"
}

variable "ned_iosxr_id" {
  type    = string
  default = "cisco-iosxr-cli-7.33"
}

variable "ned_nx" {
  type    = string
  default = "ncs-5.5-cisco-nx-5.21.4"
}

variable "ned_nx_id" {
  type    = string
  default = "cisco-nx-cli-5.21"
}
variable "ned_asa" {
  type    = string
  default = "ncs-5.5-cisco-asa-6.12.4"
}

variable "ned_asa_id" {
  type    = string
  default = "cisco-asa-cli-6.7"
}

variable "vm_name" {
  type    = string
  default = "ubuntuNSO"
}

source "qemu" "build_nso" {
  accelerator               = "kvm"
  cd_files                  = ["./isoData/build/*"]
  cd_label                  = "cidata"
  disk_compression          = true
  disk_image                = true
  disk_size                 = var.disk_size
  format                    = "qcow2"
  headless                  = true
#  http_directory            = "installResources"
  iso_checksum              = var.iso_checksum
  iso_url                   = var.iso_url
  output_directory          = "output-${var.vm_name}-${var.nso_version}"
  qemuargs                  = [
    ["-m", "${var.memory}"],
    ["-smp", "${var.cpus}"],
    ["-serial", "mon:stdio"]
  ]
  ssh_clear_authorized_keys = true  # This shouldn't be needed, but just in case...
  ssh_password              = var.ssh_password
  ssh_port                  = 22
  ssh_timeout               = "300s"
  ssh_username              = var.ssh_username
  use_default_display       = true
  vm_name                   = "${var.vm_name}-${var.nso_version}-${formatdate("YYYYMMDD", timestamp())}.qcow2"
}

build {
  sources = ["source.qemu.build_nso"]

  provisioner "file" {
    destination = "/tmp/"
    source      = "./installResources/requirements.txt"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "./installResources/nso-${var.nso_version}.linux.x86_64.installer.bin"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "./installResources/${var.ned_ios}.tar.gz"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "./installResources/${var.ned_iosxr}.tar.gz"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "./installResources/${var.ned_nx}.tar.gz"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "./installResources/${var.ned_asa}.tar.gz"
  }
  provisioner "shell" {
    environment_vars = [
      "UPDATE_OS=${var.update_os}",
      "SSH_USERNAME=${var.ssh_username}",
      "SSH_PASSWORD=${var.ssh_password}",
      "HTTP_URL=http://${build.PackerHTTPAddr}",
      "INSTALL_DIR=${var.install_directory}",
      "NSO_VER=${var.nso_version}",
      "NSO_JAVA_OPTS=${var.nso_java_opts}",
      "NED_IOS=${var.ned_ios}",
      "NED_XR=${var.ned_iosxr}",
      "NED_NX=${var.ned_nx}",
      "NED_ASA=${var.ned_asa}",
      "NED_IOS_ID=${var.ned_ios_id}",
      "NED_XR_ID=${var.ned_iosxr_id}",
      "NED_NX_ID=${var.ned_nx_id}",
      "NED_ASA_ID=${var.ned_asa_id}"
    ]
    execute_command  = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts          = [
      "scripts/updateOS.sh",
      "scripts/packages.sh",
      "scripts/installNSO.sh",
      "scripts/cleanup.sh"
    ]
  }
}
