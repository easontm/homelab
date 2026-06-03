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
  external_service_urls = {
    authelia = { url = "10.10.30.2:9091", subdomain = "auth" }
    # homebox  = { url = "10.10.30.3:7745", subdomain = "homebox" }
  }
  k8s_service_routes = {
    "paperless-ngx" = {
      subdomain = "paperless"
      namespace = "paperless-ngx"
      service   = "webserver"
      port      = 8000
    }
    "homebox" = {
      subdomain = "homebox"
      namespace = "homebox"
      service   = "homebox"
      port      = 7745
    }
    "lldap" = {
      subdomain = "lldap"
      namespace = "lldap"
      service   = "lldap-web"
      port      = 17170
    "authelia-helm" = {
      subdomain = "authelia"
      namespace = "authelia"
      service   = "authelia"
      port      = 80
    }
  }
  common_name = "*.${local.traefik_vars.domain}"
  dns_names   = ["*.${local.traefik_vars.domain}"]
  cloudflare_origin_ca_cert = local.traefik_vars.cloudflare_origin_cert
  cloudflare_origin_ca_key  = local.traefik_vars.cloudflare_origin_key
  replica_count = 2
}
