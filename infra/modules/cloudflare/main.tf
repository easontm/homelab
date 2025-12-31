terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "ingress" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ingress_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.ingress.id
  source     = "cloudflare"
  config = {
    ingress = concat(
      var.ingress_rules,
      [{ service = "http_status:404" }]
    ),
  }
}

resource "cloudflare_dns_record" "example_dns_record" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  ttl     = 1
  type    = "CNAME"
  comment = "Managed by Terraform"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.ingress.id}.cfargotunnel.com"
  proxied = true
}