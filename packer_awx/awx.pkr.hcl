# AWX VM image

variable "awx_resource_dir" {
  type    = string
  default = "/etc/awx"
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "6G"
}

variable "iso_checksum" {
  type    = string
#  default = "sha256:7aa62a5739ce1edb08364384a83224475e9420442af9332f1e73bb0f56c8de8e"
}

variable "iso_url" {
  type    = string
  default = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "k3s_images" {
  type    = list(string)
  default = []
}

# K3s defaults to containerd as a CRI, but you can add Docker on top if needed.
#
# Note if you want the install to try to pre-populate the container images, then you
# need to set this to true. Not using Docker will result in a much smaller image size,
# but a longer initial startup time for AWX
variable "k3s_use_docker" {
  type    = bool
  default = false
}

variable "k3s_version" {
  type    = string
  default = "1.19.9"
}

variable "memory" {
  type    = string
  default = "4096M"
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
  default = "focal-awx"
}

source "qemu" "build_awx" {
  accelerator               = "kvm"
  cd_files                  = ["./isoData/build/*"]
  cd_label                  = "cidata"
  disk_compression          = true
  disk_image                = true
  disk_size                 = var.disk_size
  format                    = "qcow2"
  headless                  = true
  iso_checksum              = var.iso_checksum
  iso_url                   = var.iso_url
  output_directory          = "output-${var.vm_name}"
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
  vm_name                   = "${var.vm_name}-${formatdate("YYYYMMDD", timestamp())}.qcow2"
}

build {
  sources = ["source.qemu.build_awx"]

  provisioner "file" {
    destination = "${var.upload_directory}/"
    source      = "./installResources/awx.yaml"
  }
  provisioner "file" {
    destination = "${var.upload_directory}/"
    source      = "./installResources/startup.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "AWX_RESOURCE_DIR=${var.awx_resource_dir}",
      "K3S_IMAGES=${join(" ",var.k3s_images)}",   # These quotes look wrong, but it works
      "K3S_USE_DOCKER=${var.k3s_use_docker}",
      "K3S_VER=${var.k3s_version}",
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
