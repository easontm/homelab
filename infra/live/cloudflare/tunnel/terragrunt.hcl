include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  api_token      = get_env("CLOUDFLARE_API_TOKEN")
  account_id     = get_env("CLOUDFLARE_ACCOUNT_ID")
  zone_id        = get_env("CLOUDFLARE_ZONE_ID")
  cloudflare_vars = yamldecode(sops_decrypt_file("../cloudflare_vars.sops.yaml"))
}

terraform {
  source = "../../../modules/cloudflare/tunnel"
}

inputs = {
  cloudflare_api_token  = local.api_token
  cloudflare_account_id = local.account_id
  cloudflare_zone_id    = local.zone_id

  cloudflare_tunnel_name = "homelab-01"
  ingress_rules = [
    {
      hostname = "*.${local.cloudflare_vars.domain}"
      origin_request = {
        no_tls_verify = false
      }
      # There is a matching override rule in OPNsense to forward traffic to
      # the Traefik service.
      service = "https://traefik.${local.cloudflare_vars.domain}:443"
    }
  ]
}
