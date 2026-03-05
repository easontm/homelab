include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/metal-lb-k8s"
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  chart_version = "0.15.3"
  ip_ranges = ["10.10.30.240-10.10.30.253"]
}
