resource "talos_machine_secrets" "this" {
  talos_version = "1.12.4"
}

data "talos_machine_configuration" "controlplane" {
  talos_version      = "1.12.4"
  kubernetes_version = "1.35.0"
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  talos_version      = "1.12.4"
  kubernetes_version = "1.35.0"
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for k, v in var.node_data.controlplanes : k]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_vms]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.node_data.controlplanes
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/patches/hostname.yaml.tmpl", {
      hostname = each.value.hostname == null ? format("%s-cp-%s", var.cluster_name, index(keys(var.node_data.controlplanes), each.key)) : each.value.hostname
    }),
    templatefile("${path.module}/patches/install-disk.yaml.tmpl", {
      install_disk = each.value.install_disk
    }),
    templatefile("${path.module}/patches/kernel.yaml.tmpl", {
      kernels = each.value.kernels
    }),
    templatefile("${path.module}/patches/cp-scheduling.yaml.tmpl", {
      allow_scheduling = each.value.allow_scheduling
    }),
    file("${path.module}/patches/cluster-discovery.yaml"),
    file("${path.module}/patches/multipathd_extension.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_vms]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.node_data.workers
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/patches/hostname.yaml.tmpl", {
      hostname = each.value.hostname == null ? format("%s-w-%s", var.cluster_name, index(keys(var.node_data.workers), each.key)) : each.value.hostname
    }),
    templatefile("${path.module}/patches/install-disk.yaml.tmpl", {
      install_disk = each.value.install_disk
    }),
    templatefile("${path.module}/patches/kernel.yaml.tmpl", {
      kernels = each.value.kernels
    }),
    file("${path.module}/patches/cluster-discovery.yaml"),
    file("${path.module}/patches/multipathd_extension.yaml"),
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : k][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : k][0]
}
