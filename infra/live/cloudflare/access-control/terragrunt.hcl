include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  api_token      = get_env("CLOUDFLARE_API_TOKEN")
  account_id     = get_env("CLOUDFLARE_ACCOUNT_ID")
  cloudflare_vars = yamldecode(sops_decrypt_file("../cloudflare_vars.sops.yaml"))
}

terraform {
  source = "../../../modules/cloudflare/access-control"
}

inputs = {
  cloudflare_api_token  = local.api_token
  cloudflare_account_id = local.account_id

  cloudflare_one_team_name             = local.cloudflare_vars.one_team_name
  allowed_emails                       = local.cloudflare_vars.allowed_emails
  cloudflare_access_application_domain = "*.${local.cloudflare_vars.domain}"
  session_duration                     = "336h"
}
