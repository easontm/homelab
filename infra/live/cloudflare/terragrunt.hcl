locals {
  api_token = get_env("CLOUDFLARE_API_TOKEN")
  account_id = get_env("CLOUDFLARE_ACCOUNT_ID")
  zone_id = get_env("CLOUDFLARE_ZONE_ID")
}

terraform {
  source = "../../modules/cloudflare"
}

inputs = {
  cloudflare_api_token = local.api_token
  cloudflare_account_id = local.account_id
  cloudflare_zone_id = local.zone_id

  cloudflare_tunnel_name = "homelab-01"
  ingress_rules = [
    {
      hostname       = "*.easontm.com"
      origin_request = {
        no_tls_verify = true
      }
      service        = "https://192.168.1.240:443"
    }
  ]
}