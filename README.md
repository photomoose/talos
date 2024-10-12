# Talos + Cilium CNI + Promox CSI + Gateway API

This repository contains sample Terraform to create a Talos Kubernetes cluster running on Promox.

The following components will be installed:

- Talos
- Cilium (CNI)
- proxmox-csi-plugin (CSI)
- Gateway API CRDs

## Installation

Create a `backend.tf` file to store your Terraform state file, for example:

```
terraform {
  backend "s3" {
    bucket = "<your S3 bucket>"
    key    = "talos.tfstate"
    region = "eu-west-2"
  }
}
```

Configure the Promox Terraform provider with your Proxmox VE username and password by either setting the `PROXMOX_VE_USERNAME` and `PROXMOX_VE_PASSWORD` environment variables, or declaring them in `main.tf`.

Create a `terraform.tfvars` file to declare variable values that are defined in `variables.tf`. For example:

```
talos_cluster_name         = "talos-cluster"
talos_cluster_endpoint_dns = "my-cluster.homelab.co.uk"
default_gateway            = "10.0.30.1"
dns_server                 = "10.0.30.3"
dns_domain                 = "homelab.co.uk"

proxmox_endpoint     = "https://10.0.30.2:8006"
proxmox_cluster_name = "pve-cluster"

talos_control_planes = [
  {
    proxmox_vm_id     = "200"
    proxmox_vm_name   = "talos-cp-01"
    proxmox_node_name = "pve"
    ip                = "10.0.30.100"
  }
]

talos_workers = [
  {
    proxmox_vm_id     = "201"
    proxmox_vm_name   = "talos-worker-01"
    proxmox_node_name = "pve"
    ip                = "10.0.30.101"
  },
  {
    proxmox_vm_id     = "202"
    proxmox_vm_name   = "talos-worker-02"
    proxmox_node_name = "pve"
    ip                = "10.0.30.102"
  }
]
```

Execute the following to bring up the environment:

```
terraform init
terraform apply
```

## kubeconfig and talosconfig

Execute the following to get the kubeconfig and talosconfig values:

```
terraform output -raw kubeconfig

terraform output -raw talosconfig
```

## CSI Storage Class

A storage class named `proxmox-csi` should be available in the Kubernetes cluster which should automatically provision volumes as disks inside Promox.

## Gateway API

The Gateway API CRDs are automatically provisioned when Talos is bootstrapped. A `GatewayClass` named `cilium` should be automatically created by Cilium when it first starts.

## Changing inline manifests

As a safety measure, Talos only creates missing resources from inline manifests, it never deletes or updates anything.

If you need to update a manifest make sure to first edit all control plane machine configurations and then run `talosctl upgrade-k8s` as it will take care of updating inline manifests.

## Contributing

PRs are very much welcome to make this script more generic and/or include more optional features.
