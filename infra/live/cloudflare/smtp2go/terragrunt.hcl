include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  api_token       = get_env("CLOUDFLARE_API_TOKEN")
  zone_id         = get_env("CLOUDFLARE_ZONE_ID")
  # cloudflare_vars = yamldecode(sops_decrypt_file("../cloudflare_vars.sops.yaml"))
  smtp2go_vars    = yamldecode(sops_decrypt_file("./smtp2go_vars.sops.yaml"))
}

terraform {
  source = "../../../modules/cloudflare/smtp2go"
}

inputs = {
  cloudflare_api_token = local.api_token
  cloudflare_zone_id   = local.zone_id

  return_cname_name    = local.smtp2go_vars.return_cname_name
  return_cname_content = local.smtp2go_vars.return_cname_content

  dkim_cname_name    = local.smtp2go_vars.dkim_cname_name
  dkim_cname_content = local.smtp2go_vars.dkim_cname_content

  tracking_cname_name    = local.smtp2go_vars.tracking_cname_name
  tracking_cname_content = local.smtp2go_vars.tracking_cname_content
}
