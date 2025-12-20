include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/traefik-k8s"
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  chart_version = "38.0.0"
}
