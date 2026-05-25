resource "cloudflare_zero_trust_access_identity_provider" "onetimepin_login" {
  account_id = var.cloudflare_account_id
  name       = "One-time PIN login"
  type       = "onetimepin"
  config     = {}
}

resource "cloudflare_zero_trust_access_policy" "global" {
  account_id = var.cloudflare_account_id
  name       = "homelab_access"
  decision   = "allow"
  include = [
    for e in var.allowed_emails : {
      email = {
        email = e
      }
    }
  ]
  require = [
    {
      login_method = {
        id = cloudflare_zero_trust_access_identity_provider.onetimepin_login.id
      }
    }
  ]
  session_duration = var.session_duration
}

resource "cloudflare_zero_trust_access_application" "app_launcher" {
  name                = "App Launcher"
  domain              = "${var.cloudflare_one_team_name}.cloudflareaccess.com"
  type                = "app_launcher"
  landing_page_design = {}
  session_duration    = var.session_duration
  allowed_idps = [
    cloudflare_zero_trust_access_identity_provider.onetimepin_login.id
  ]
  policies = [
    {
      id = cloudflare_zero_trust_access_policy.global.id
    }
  ]
  account_id = var.cloudflare_account_id
}

resource "cloudflare_zero_trust_access_application" "homelab" {
  name             = "Homelab"
  domain           = var.cloudflare_access_application_domain
  type             = "self_hosted"
  session_duration = var.session_duration
  # may need this later
  # options_preflight_bypass = true
  allowed_idps = [
    cloudflare_zero_trust_access_identity_provider.onetimepin_login.id
  ]
  policies = [
    {
      id = cloudflare_zero_trust_access_policy.global.id
    }
  ]
  account_id = var.cloudflare_account_id
}
