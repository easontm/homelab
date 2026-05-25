variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "cloudflare_tunnel_name" {
  description = "Cloudflare Tunnel Name"
  type        = string
}

variable "ingress_rules" {
  description = "Cloudflare Tunnel Ingress Rules"
  type = list(object({
    hostname = string
    service  = string
    origin_request = optional(object({
      no_tls_verify = bool
    }))
  }))
}
