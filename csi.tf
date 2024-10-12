resource "proxmox_virtual_environment_role" "csi" {
  role_id = var.proxmox_csi_role_id
  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit"
  ]
}

resource "proxmox_virtual_environment_user" "kubernetes_csi" {
  user_id = var.proxmox_csi_user_id
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }
}

resource "proxmox_virtual_environment_user_token" "kubernetes_csi_token" {
  comment               = "Managed by Terraform"
  expiration_date       = "2033-01-01T22:00:00Z"
  token_name            = var.proxmox_csi_token_name
  user_id               = proxmox_virtual_environment_user.kubernetes_csi.user_id
  privileges_separation = false
}

output "proxmox_csi_token" {
  value     = split("=", proxmox_virtual_environment_user_token.kubernetes_csi_token.value)[1]
  sensitive = true
}

data "helm_template" "proxmox_csi_plugin" {
  namespace    = "csi-proxmox"
  name         = "cilium"
  repository   = "oci://ghcr.io/sergelogvinov/charts"
  chart        = "proxmox-csi-plugin"
  version      = "0.2.13"
  kube_version = var.kubernetes_version
  api_versions = []
  set {
    name  = "createNamespace"
    value = "true"
  }
  set {
    name  = "config.clusters[0].url"
    value = "${var.proxmox_endpoint}/api2/json"
  }
  set {
    name  = "config.clusters[0].insecure"
    value = "true"
  }
  set {
    name  = "config.clusters[0].token_id"
    value = proxmox_virtual_environment_user_token.kubernetes_csi_token.id
  }
  set {
    name  = "config.clusters[0].token_secret"
    value = split("=", proxmox_virtual_environment_user_token.kubernetes_csi_token.value)[1]
  }
  set {
    name  = "config.clusters[0].region"
    value = var.proxmox_cluster_name
  }
  set {
    name  = "storageClass[0].name"
    value = "proxmox-csi"
  }
  set {
    name  = "storageClass[0].storage"
    value = "local-lvm"
  }
  set {
    name  = "storageClass[0].reclaimPolicy"
    value = "Retain"
  }
  set {
    name  = "storageClass[0].fstype"
    value = "ext4"
  }
  set {
    name  = "storageClass[0].cache"
    value = "writethrough"
  }
  set {
    name  = "storageClass[0].ssd"
    value = "true"
  }
  set {
    name  = "storageClass[0].mountOptions[0]"
    value = "noatime"
  }
}
