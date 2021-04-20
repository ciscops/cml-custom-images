# Creating a Cisco NSO VM image, mainly for CML2

variable "cpus" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "4G"
}

variable "iso_checksum" {
  type    = string
#  default = "sha256:38b82727bfc1b36d9784bf07b8368c1d777450e978837e1cd7fa32b31837e77c"
}

variable "iso_url" {
  type    = string
  default = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "memory" {
  type    = string
  default = "2048M"
}

variable "nso_install_directory" {
  type    = string
  default = "/pkgs/nso-install"
}

variable "nso_java_opts" {
  type    = string
  default = "-Xmx2G -Xms1G"
}

# Some NSO packages still require Java 8 (previous LTS release)
variable "nso_java_version" {
  type    = string
  default = "11"
  validation {
    condition     = contains(["8", "11"], var.nso_java_version)
    error_message = "Java version for NSO must be \"8\" or \"11\"."
  }
}

variable "nso_ned_list" {
  type    = list(string)
  default = []
}

variable "nso_run_directory" {
  type    = string
  default = "/home/ubuntu/ncs-run"
}

variable "nso_version" {
  type    = string
  default = "5.4.3"
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

variable "upload_directory" {
  type    = string
  default = "/tmp"
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
    destination = "${var.upload_directory}/"
    source      = "./installResources/requirements.txt"
  }
  provisioner "file" {
    destination = "${var.upload_directory}/"
    source      = fileexists("./installResources/nso-${var.nso_version}.linux.x86_64.signed.bin") ? "./installResources/nso-${var.nso_version}.linux.x86_64.signed.bin" : "./installResources/nso-${var.nso_version}.linux.x86_64.installer.bin"
  }
  provisioner "file" {
    destination = "${var.upload_directory}/"
    sources     = [for ned in var.nso_ned_list : "./installResources/${ned}"]
  }

  provisioner "shell" {
    environment_vars = [
      "INSTALL_DIR=${var.nso_install_directory}",
      #"HTTP_URL=http://${build.PackerHTTPAddr}",
      "NSO_JAVA_OPTS=${var.nso_java_opts}",
      "NSO_JAVA_VERSION=${var.nso_java_version}",
      "NSO_VER=${var.nso_version}",
      "RUN_DIR=${var.nso_run_directory}",
      "SSH_PASSWORD=${var.ssh_password}",
      "SSH_USERNAME=${var.ssh_username}",
      "UPDATE_OS=${var.update_os}",
      "UPLOAD_DIR=${var.upload_directory}",
    ]
    execute_command  = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts          = [
      "scripts/updateOS.sh",
      "scripts/packages.sh",
      "scripts/installMain.sh",
      "scripts/cleanup.sh"
    ]
  }
}
