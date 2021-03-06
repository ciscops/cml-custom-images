# Creating a Netbox VM image, mainly for CML2

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
#  default = "sha256:db5969e16940d67184adb740db1b1f186b201714430737ea1c64a85e40d25f6b"
}

variable "iso_url" {
  type    = string
  default = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "memory" {
  type    = string
  default = "2048M"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "netbox_db_password" {
  type    = string
  default = "somehardtoguesspassword"
}

variable "netbox_password" {
  type    = string
  default = "admin"
}

variable "netbox_username" {
  type    = string
  default = "admin"
}

variable "netbox_email" {
  type    = string
  default = "admin@example.net"
}

variable "update_os" {
  type    = string
  default = "true"
}

variable "vm_name" {
  type    = string
  default = "ubuntuNETBOX"
}

source "qemu" "build_netbox" {
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
  output_directory          = "output-netbox"
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
  vm_name                   = "netbox-${formatdate("YYYYMMDD", timestamp())}.qcow2"
}

build {
  sources = ["source.qemu.build_netbox"]

  provisioner "shell" {
    environment_vars = [
      "UPDATE_OS=${var.update_os}",
      "SSH_USERNAME=${var.ssh_username}",
      "SSH_PASSWORD=${var.ssh_password}",
      "NETBOX_DB_PASSWORD=${var.netbox_db_password}",
      "DJANGO_SUPERUSER_USERNAME=${var.netbox_username}",
      "DJANGO_SUPERUSER_PASSWORD=${var.netbox_password}",
      "DJANGO_SUPERUSER_EMAIL=${var.netbox_email}"
    ]
    execute_command  = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E bash -x '{{ .Path }}'"
    scripts          = [
      "scripts/updateOS.sh",
      "scripts/packages.sh",
      "scripts/installMain.sh",
      "scripts/cleanup.sh"
    ]
  }
}
