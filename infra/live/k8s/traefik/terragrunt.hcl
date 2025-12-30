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

  traefik_granted_namespaces = [
    "paperless-ngx",
  ]
  authelia_service_url = "http://192.168.1.103:9091/api/authz/forward-auth"
  common_name = "*.easontm.com"
  dns_names   = ["*.easontm.com"]
}
