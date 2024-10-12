locals {
  proxmox_nodes = distinct(concat(var.talos_control_planes[*].proxmox_node_name, var.talos_workers[*].proxmox_node_name))
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  count                   = length(local.proxmox_nodes)
  content_type            = "iso"
  datastore_id            = "local"
  node_name               = local.proxmox_nodes[count.index]
  file_name               = "talos-${var.talos_version}-nocloud-amd64.img"
  url                     = "https://factory.talos.dev/image/787b79bb847a07ebb9ae37396d015617266b1cef861107eaec85968ad7b40618/${var.talos_version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
