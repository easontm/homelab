variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cloudflare_one_team_name" {
  description = "Cloudflare One Team Name"
  type        = string
}

variable "allowed_emails" {
  description = "Email allowlist"
  type        = list(string)
  default     = []
}

variable "session_duration" {
  description = "Cloudflare Access Session Duration"
  type        = string
  default     = "72h"
}

variable "cloudflare_access_application_domain" {
  description = "Cloudflare Access Application Domain"
  type        = string
}
