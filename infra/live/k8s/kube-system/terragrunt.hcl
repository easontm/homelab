include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/nfs-csi"
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  chart_version  = "4.12.1"
  storage_class_name = "nfs-retain"
  nfs_server = "192.168.1.254"
  nfs_path = "/mnt/volume1/proxmox/k8s/nfs-01"
  test = false
}
