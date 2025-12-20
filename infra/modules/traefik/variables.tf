##############
# Global
##############
variable "target_node" {
  description = "Proxmox Target Node"
  type        = string
}

variable "vmid" {
  description = "VMID for the container"
  type        = number
}

##############
# Ansible
##############
variable "ansible_user" {
  description = "Ansible user for remote connection"
  type        = string
  default     = "ansible"
}

##############
# Container
##############

variable "host_name" {
  description = "Hostname for the LXC container"
  type        = string
  default     = "traefik"
}

variable "template_storage" {
  description = "Datastore where the LXC template is stored"
  type        = string
}

variable "container_repository" {
  description = "OCI Container Repository"
  type        = string
}

variable "container_tag" {
  description = "OCI Container Tag"
  type        = string
  default     = "latest"
}

variable "rootfs" {
  description = "Root filesystem configuration for the LXC container"
  type = object({
    storage = string
    size    = string
  })
  default = {
    storage = "local-lvm"
    size    = "4"
  }
}

variable "mac_address" {
  description = "MAC address for the container's network interface"
  type        = string
  nullable    = true
}

##############
# Traefik
##############

variable "dashboard_enabled" {
  description = "Enable Traefik dashboard"
  type        = bool
  default     = true
}

variable "insecure_dashboard" {
  description = "Enable insecure access to Traefik dashboard"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Traefik log level"
  type        = string
  default     = "INFO"
}

variable "middlewares" {
  description = "Traefik middlewares configuration"
  type        = map(any)
}

variable "services" {
  description = "Traefik services configuration"
  type        = map(any)
}

variable "routers" {
  description = "Traefik routers configuration"
  type        = map(any)
}

variable "k8s_gateway" {
  description = "Kubernetes Gateway configuration (optional)"
  type = object({
    endpoint         = string
    token            = string
    certAuthFilePath = string
    cert             = string
  })
  nullable = true
  default = null
}

locals {
  k8s_gateway_yaml = yamlencode({
    for key, value in var.k8s_gateway :
    key => value
    if key != "cert"
  })
  middlewares_yaml = yamlencode(var.middlewares)
  services_yaml    = yamlencode(var.services)
  routers_yaml     = yamlencode(var.routers)
}
