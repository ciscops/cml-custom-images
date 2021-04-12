# Checksum from 20210407 Ubuntu Focal cloud image
iso_checksum = "sha256:7aa62a5739ce1edb08364384a83224475e9420442af9332f1e73bb0f56c8de8e"
iso_url = "focal-server-cloudimg-amd64.img"
vm_name = "focal-awx"

k3s_version = "1.20.5"
# Use Docker if you want the install to try to pre-populate the image cache
k3s_use_docker = true
# This K3s image list is valid for 1.20.5 as of 20210409
k3s_images = [
  "rancher/coredns-coredns:1.8.0",
  "rancher/local-path-provisioner:v0.0.19",
  "rancher/library-busybox:1.32.1",
  "rancher/metrics-server:v0.3.6",
  "rancher/library-traefik:1.7.19",
  "rancher/klipper-helm:v0.4.3",
  "rancher/klipper-lb:v0.1.2",
]