variable "proxmox_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API, e.g. https://<your-cluster-endpoint>:8006"
}

variable "proxmox_cluster_name" {
  type        = string
  description = "The name of Proxmox cluster, as configured in the Proxmox UI. Used to configure Kubernetes topology labels."
}

variable "proxmox_csi_user_id" {
  type        = string
  description = "The name of the user to create for the CSI plugin."
  default     = "kubernetes-csi@pve"
}

variable "proxmox_csi_role_id" {
  type        = string
  description = "The name of the role to create to assign to the CSI plugin user."
  default     = "CSI"
}

variable "proxmox_csi_token_name" {
  type        = string
  description = "The name of the API token to create for the CSI plugin user."
  default     = "csi"
}

variable "talos_version" {
  type        = string
  description = "The version of Talos to install."
  default     = "v1.8.0"
}

variable "talos_cluster_name" {
  type        = string
  description = "The name of the Talos Kubernetes cluster"
}

variable "talos_cluster_endpoint_dns" {
  type        = string
  description = <<EOF
    An optional resolvable DNS name that points to the Talos Kubernetes cluster API endpoint on all control plane nodes. 
    Will default to the IP address of the first control plane node if not set.

    See https://www.talos.dev/v1.5/kubernetes-guides/configuration/cluster-endpoint/"
  EOF
  default     = null
}

variable "default_gateway" {
  type        = string
  description = "The IP of the default gateway to be used by the Proxmox VMs."
}

variable "dns_server" {
  type        = string
  description = "The IP of the DNS server to be used by the Proxmox VMs."
}

variable "dns_domain" {
  type        = string
  description = "The DNS search domain to be used by the Proxmox VMs."
}

variable "talos_control_planes" {
  description = <<EOF
    A list of control plane nodes/VMs to create.

    proxmox_vm_id     - The ID of the Proxmox VM
    proxmox_vm_name   - The name of the Proxmox VM
    proxmox_node_name - The name of the Proxmox node within the Proxmox cluster that the VM will run on. Used to configure Kubernetes topology labels.
    ip                - The IP address to assign to the Proxmox VM 
  EOF
  type = list(
    object(
      {
        proxmox_vm_id     = string
        proxmox_vm_name   = string
        proxmox_node_name = string
        ip                = string
      }
    )
  )
}

variable "talos_workers" {
  description = <<EOF
    A list of worker nodes/VMs to create.

    proxmox_vm_id     - The ID of the Proxmox VM
    proxmox_vm_name   - The name of the Proxmox VM
    proxmox_node_name - The name of the Proxmox node within the Proxmox cluster that the VM will run on. Used to configure Kubernetes topology labels.
    ip                - The IP address to assign to the Proxmox VM 
  EOF
  type = list(
    object(
      {
        proxmox_vm_id     = string
        proxmox_vm_name   = string
        proxmox_node_name = string
        ip                = string
      }
    )
  )
}

# see https://github.com/siderolabs/kubelet/pkgs/container/kubelet
# see https://www.talos.dev/v1.7/introduction/support-matrix/
variable "kubernetes_version" {
  type = string
  # renovate: datasource=github-releases depName=siderolabs/kubelet
  default = "1.31.1"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.kubernetes_version))
    error_message = "Must be a version number."
  }
}
