include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "proxmox" {
  path           = find_in_parent_folders("proxmox.hcl")
  expose         = true
  merge_strategy = "deep"
}

generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents = replace(
    file("${get_repo_root()}/infra/modules/providers.tf"),
    "  }\n}",
    "    talos = {\n      source  = \"siderolabs/talos\"\n      version = \"0.11.0-beta.1\"\n    }\n  }\n}"
  )
}

terraform {
  source = "../../../modules/talos"
}

locals {
  kernels = [
    "dm_multipath",
    "dm_round-robin",
  ]
}

inputs = {
  vm_disk_datastore_id = "pve-shared"
  vm_network_bridge = "vmbr30"
  gateway_ip = "10.10.30.1"

  talos_disk_node_name = "pve3"
  talos_disk_file_name = "talos-nfs-iscsi-nocloud-amd64.raw"

  cluster_name = "talos-cluster"
  cluster_endpoint = "https://10.10.30.100:6443"
  
  node_data = {
    controlplanes = {
      "10.10.30.100" = {
        pve_node     = "pve4"
        vmid         = 800
        install_disk = "/dev/sda"
        hostname     = "k8s-controlplane-1"
        cpu_cores    = 2
        memory_mb    = 2048
        kernels      = local.kernels
        allow_scheduling = true
      },
    }
    workers = {
      "10.10.30.111" = {
        pve_node     = "pve1"
        vmid         = 810
        install_disk = "/dev/sda"
        hostname     = "k8s-worker-1"
        cpu_cores    = 2
        memory_mb    = 4096
        kernels      = local.kernels
      },
      "10.10.30.112" = {
        pve_node     = "pve3"
        vmid         = 811
        install_disk = "/dev/sda"
        hostname     = "k8s-worker-2"
        cpu_cores    = 2
        memory_mb    = 8192
        kernels      = local.kernels
      },
      "10.10.30.113" = {
        pve_node     = "pve5"
        vmid         = 812
        install_disk = "/dev/sda"
        hostname     = "k8s-worker-3"
        cpu_cores    = 2
        memory_mb    = 2048
        kernels      = local.kernels
      },
    }
  }
}
