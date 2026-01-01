##############
# Cloudflare
##############
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
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

variable "traefik_service_ip" {
  description = "IP address of the Traefik service from the point of view of the tunnel daemon. Can be local."
  type        = string
}

##############
# Access Controls
##############
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

##############
# Proxmox
##############
# variable "target_node" {
#   description = "Proxmox Target Node"
#   type        = string
# }

# variable "vmid" {
#   description = "VMID for the container"
#   type        = number
# }

# variable "container_repository" {
#   description = "OCI Container Repository"
#   type        = string
#   default     = "cloudflare/cloudflared"
# }

# variable "container_tag" {
#   description = "OCI Container Tag"
#   type        = string
#   default     = "latest"
# }

# variable "host_name" {
#   description = "Hostname for the LXC container"
#   type        = string
#   default     = "cloudflared"
# }

# variable "template_storage" {
#   description = "Datastore where the LXC template is stored"
#   type        = string
# }

# variable "rootfs" {
#   description = "Root filesystem configuration for the LXC container"
#   type = object({
#     storage = string
#     size    = string
#   })
#   default = {
#     storage = "local-lvm"
#     size    = "4"
#   }
# }
