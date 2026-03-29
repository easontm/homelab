include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/velero"
}

locals {
  credentials = yamldecode(sops_decrypt_file("./credentials.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  namespace = "velero"
  chart_version = "1.18.0"

  key_id = local.credentials.aws_access_key_id
  secret_key = local.credentials.aws_secret_access_key
}
