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
  source = "../../../modules/cloudflare/email-forwarding"
}

inputs = {
  cloudflare_api_token  = local.api_token
  cloudflare_account_id = local.account_id
  cloudflare_zone_id    = local.zone_id

  email_routing_destination = local.cloudflare_vars.email_routing_destination
  email_routing_rules = [
    {
      matcher_value = "homelab@${local.cloudflare_vars.domain}"
      action_value  = local.cloudflare_vars.email_routing_destination
    }
  ]
}
