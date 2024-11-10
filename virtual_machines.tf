resource "proxmox_virtual_environment_vm" "talos_cp" {
  count       = length(var.talos_control_planes)
  name        = var.talos_control_planes[count.index].proxmox_vm_name
  vm_id       = var.talos_control_planes[count.index].proxmox_vm_id
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = var.talos_control_planes[count.index].proxmox_node_name
  on_boot     = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = "30"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image[index(proxmox_virtual_environment_download_file.talos_nocloud_image.*.node_name, var.talos_control_planes[count.index].proxmox_node_name)].id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.talos_control_planes[count.index].ip}/24"
        gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
    dns {
      domain  = var.dns_domain
      servers = [var.dns_server]
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  count       = length(var.talos_workers)
  depends_on  = [proxmox_virtual_environment_vm.talos_cp]
  name        = var.talos_workers[count.index].proxmox_vm_name
  vm_id       = var.talos_workers[count.index].proxmox_vm_id
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = var.talos_workers[count.index].proxmox_node_name
  on_boot     = true

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = "30"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image[index(proxmox_virtual_environment_download_file.talos_nocloud_image.*.node_name, var.talos_workers[count.index].proxmox_node_name)].id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.talos_workers[count.index].ip}/24"
        gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
    dns {
      domain  = var.dns_domain
      servers = [var.dns_server]
    }
  }
}
