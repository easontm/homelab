include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/democratic-csi"
}

locals {
  democratic_vars = yamldecode(sops_decrypt_file("./democratic_csi_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  snapshot_chart_version = "0.3.0"
  csi_chart_version   = "0.15.0"
  truenas_host    = local.democratic_vars.truenas_host
  truenas_api_key = local.democratic_vars.truenas_api_key
  storage_class_name = "iscsi-retain"
  volume_path     = "volume1/proxmox/k8s/iscsi/volumes"
  snapshot_path   = "volume1/proxmox/k8s/iscsi/snapshots"
  portal_group_id = 1
  initiator_group_id = 2
  test = false
}
