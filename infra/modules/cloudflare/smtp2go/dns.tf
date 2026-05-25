resource "cloudflare_dns_record" "return_path" {
  zone_id = var.cloudflare_zone_id
  type    = "CNAME"
  name    = var.return_cname_name
  content = var.return_cname_content
  ttl     = 1
  proxied = false
  comment = "SMTP2GO return-path — Managed by Terraform"
}

resource "cloudflare_dns_record" "dkim" {
  zone_id = var.cloudflare_zone_id
  type    = "CNAME"
  name    = var.dkim_cname_name
  content = var.dkim_cname_content
  ttl     = 1
  proxied = false
  comment = "SMTP2GO DKIM — Managed by Terraform"
}

resource "cloudflare_dns_record" "tracking" {
  zone_id = var.cloudflare_zone_id
  type    = "CNAME"
  name    = var.tracking_cname_name
  content = var.tracking_cname_content
  ttl     = 1
  proxied = false
  comment = "SMTP2GO tracking — Managed by Terraform"
}
