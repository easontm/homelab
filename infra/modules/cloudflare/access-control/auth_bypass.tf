resource "cloudflare_zero_trust_access_policy" "auth_bypass" {
  count      = var.enable_auth_bypass ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = "OIDC Bypass"
  decision   = "bypass"
  include    = [{ everyone = {} }]
  connection_rules = {
    rdp = {}
  }
}

resource "cloudflare_zero_trust_access_application" "auth" {
  count            = var.enable_auth_bypass ? 1 : 0
  account_id       = var.cloudflare_account_id
  name             = "auth"
  domain           = "auth.${var.cloudflare_access_application_domain}/.well-known/*"
  type             = "self_hosted"
  session_duration = "24h"
  policies = [
    {
      id = cloudflare_zero_trust_access_policy.auth_bypass[0].id
    }
  ]
  destinations = [
    {
      type = "public"
      uri  = "auth.${var.cloudflare_access_application_domain}/.well-known/*"
    },
    {
      type = "public"
      uri  = "auth.${var.cloudflare_access_application_domain}/api/oidc/*"
    },
    {
      type = "public"
      uri  = "auth.${var.cloudflare_access_application_domain}/jwks.json"
    },
  ]
}

# tg import 'cloudflare_zero_trust_access_application.auth' 'accounts/b3419b5e6de3cd5272954c4cb965b773/2438082c-fc4c-4334-ad90-16fa49ce4323'
