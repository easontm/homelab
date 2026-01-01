include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/traefik-k8s"
}

locals {
  traefik_vars = yamldecode(sops_decrypt_file("./traefik_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  chart_version = "38.0.0"

  domain_name = local.traefik_vars.domain
  traefik_granted_namespaces = [
    "paperless-ngx",
  ]
  authelia_service_url = "http://192.168.1.103:9091/api/authz/forward-auth"
  common_name = "*.${local.traefik_vars.domain}"
  dns_names   = ["*.${local.traefik_vars.domain}"]
  cloudflare_origin_ca_cert = local.traefik_vars.cloudflare_origin_cert
  cloudflare_origin_ca_key  = local.traefik_vars.cloudflare_origin_key
}
