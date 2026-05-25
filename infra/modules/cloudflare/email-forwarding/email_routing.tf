# Note: the destination address (email_routing_destination) must be verified by Cloudflare.
# After applying this for the first time, Cloudflare will send a verification email to the
# destination address. The routing rule will not activate until verification is complete.
#
# Required API token permissions:
#   - Email Routing Rules Read/Write
#   - Email Routing Addresses Read/Write
#   - Zone Settings Read/Write

resource "cloudflare_email_routing_settings" "main" {
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_email_routing_address" "destination" {
  account_id = var.cloudflare_account_id
  email      = var.email_routing_destination
}

resource "cloudflare_email_routing_rule" "rules" {
  for_each = { for rule in var.email_routing_rules : rule.matcher_value => rule }

  zone_id = var.cloudflare_zone_id
  name    = "Forward ${each.key}"
  enabled = true

  matchers = [{
    type  = "literal"
    field = "to"
    value = each.key
  }]

  actions = [{
    type  = "forward"
    value = [each.value.action_value]
  }]

  depends_on = [
    cloudflare_email_routing_settings.main,
    cloudflare_email_routing_address.destination,
  ]
}
