locals {
  api_token = get_env("CLOUDFLARE_API_TOKEN")
  account_id = get_env("CLOUDFLARE_ACCOUNT_ID")
  zone_id = get_env("CLOUDFLARE_ZONE_ID")
  cloudflare_vars = yamldecode(sops_decrypt_file("./cloudflare_vars.sops.yaml"))
}

terraform {
  source = "../../modules/cloudflare"
}

inputs = {
  cloudflare_api_token  = local.api_token
  cloudflare_account_id = local.account_id
  cloudflare_zone_id    = local.zone_id

  cloudflare_tunnel_name = "homelab-01"
  ingress_rules = [
    {
      hostname       = "*.${local.cloudflare_vars.domain}"
      origin_request = {
        no_tls_verify = false
      }
      service        = "https://traefik.${local.cloudflare_vars.domain}:443"
    }
  ]

  cloudflare_one_team_name             = local.cloudflare_vars.one_team_name
  allowed_emails                       = local.cloudflare_vars.allowed_emails
  cloudflare_access_application_domain = "*.${local.cloudflare_vars.domain}"
  traefik_service_ip                   = "192.168.1.240"
}
