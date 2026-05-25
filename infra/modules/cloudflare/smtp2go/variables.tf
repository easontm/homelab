variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "return_cname_name" {
  description = "Subdomain name for the SMTP2GO return-path CNAME (e.g. 'return')"
  type        = string
}

variable "return_cname_content" {
  description = "Target for the SMTP2GO return-path CNAME"
  type        = string
}

variable "dkim_cname_name" {
  description = "Subdomain name for the SMTP2GO DKIM CNAME (e.g. 'k1._domainkey')"
  type        = string
}

variable "dkim_cname_content" {
  description = "Target for the SMTP2GO DKIM CNAME"
  type        = string
}

variable "tracking_cname_name" {
  description = "Subdomain name for the SMTP2GO tracking CNAME (e.g. 'track')"
  type        = string
}

variable "tracking_cname_content" {
  description = "Target for the SMTP2GO tracking CNAME"
  type        = string
}
