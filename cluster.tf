resource "talos_machine_secrets" "machine_secrets" {}

data "local_file" "gw_gateway_classes" {
  filename = "${path.module}/gateway-api/gateway.networking.k8s.io_gatewayclasses.yaml"
}

data "local_file" "gw_gateways" {
  filename = "${path.module}/gateway-api/gateway.networking.k8s.io_gateways.yaml"
}

data "local_file" "gw_grpc_routes" {
  filename = "${path.module}/gateway-api/gateway.networking.k8s.io_grpcroutes.yaml"
}

data "local_file" "gw_http_routes" {
  filename = "${path.module}/gateway-api/gateway.networking.k8s.io_httproutes.yaml"
}

data "local_file" "gw_reference_grants" {
  filename = "${path.module}/gateway-api/gateway.networking.k8s.io_referencegrants.yaml"
}

data "local_file" "gw_tls_routes" {
  filename = "${path.module}/gateway-api/gateway.networking.k8s.io_tlsroutes.yaml"
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = var.talos_control_planes[*].ip
}

locals {
  cluster_endpoint = "https://${coalesce(var.talos_cluster_endpoint_dns, var.talos_control_planes[0].ip)}:6443"
}

data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  count                       = length(var.talos_control_planes)
  depends_on                  = [proxmox_virtual_environment_vm.talos_cp]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration
  node                        = var.talos_control_planes[count.index].ip
  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = {
          "topology.kubernetes.io/region" = var.proxmox_cluster_name
          "topology.kubernetes.io/zone"   = var.talos_control_planes[count.index].proxmox_node_name
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
        inlineManifests = [
          {
            name     = "gw_gateway_classes"
            contents = data.local_file.gw_gateway_classes.content
          },
          {
            name     = "gw_gateways"
            contents = data.local_file.gw_gateways.content
          },
          {
            name     = "gw_grpc_routes"
            contents = data.local_file.gw_grpc_routes.content
          },
          {
            name     = "gw_http_routes"
            contents = data.local_file.gw_http_routes.content
          },
          {
            name     = "gw_reference_grants"
            contents = data.local_file.gw_reference_grants.content
          },
          {
            name     = "gw_tls_routes"
            contents = data.local_file.gw_tls_routes.content
          },
          {
            name     = "cilium"
            contents = data.helm_template.cilium.manifest
          },
          {
            name     = "proxmox-csi-pliugin"
            contents = data.helm_template.proxmox_csi_plugin.manifest
          }
        ]
      }
    })
  ]
}

data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  count                       = length(var.talos_workers)
  depends_on                  = [proxmox_virtual_environment_vm.talos_worker]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
  node                        = var.talos_workers[count.index].ip
  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = {
          "topology.kubernetes.io/region" = var.proxmox_cluster_name
          "topology.kubernetes.io/zone"   = var.talos_workers[count.index].proxmox_node_name
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.talos_control_planes[0].ip
}

data "talos_cluster_health" "health" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes  = var.talos_control_planes[*].ip
  worker_nodes         = var.talos_workers[*].ip
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.talos_control_planes[0].ip
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}
