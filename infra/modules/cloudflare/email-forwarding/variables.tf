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

variable "email_routing_destination" {
  description = "Destination email address for forwarding (must be verified via Cloudflare confirmation email)"
  type        = string
  sensitive   = true
}

variable "email_routing_rules" {
  description = "Email routing rules mapping source addresses to the destination"
  type = list(object({
    matcher_value = string
    action_value  = string
  }))
  default = []
}
