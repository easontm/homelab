variable "replica_count" {
  description = "Number of Traefik replicas to deploy"
  type        = number
  default     = 1
}
variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "traefik_namespace" {
  description = "Kubernetes namespace where Traefik will be deployed"
  type        = string
  default     = "traefik"
}

variable "chart_version" {
  description = "Version of the Traefik Helm chart to deploy"
  type        = string
}

variable "external_service_urls" {
  description = "Map of external service names to their URL and subdomain. URL should be in host:port format."
  type = map(object({
    url       = string
    subdomain = string
  }))
}

variable "k8s_service_routes" {
  description = "Map of in-cluster HTTPRoutes to create. The map key is used as the route name and resource identifier. Each entry specifies the subdomain, backend service namespace/name/port, and whether the authelia auth middleware should be applied."
  type = map(object({
    subdomain = string
    namespace = string
    service   = string
    port      = number
    auth      = optional(bool, true)
  }))
  default = {}
}

variable "domain_name" {
  description = "Domain name for Traefik"
  type        = string
}

#################
# Cert Things
#################
variable "common_name" {
  description = "Common name for the TLS certificate"
  type        = string
}

variable "dns_names" {
  description = "DNS names for the TLS certificate"
  type        = list(string)
}

variable "cloudflare_origin_ca_cert" {
  description = "Cloudflare Origin CA Certificate"
  type        = string
  default     = ""
}

variable "cloudflare_origin_ca_key" {
  description = "Cloudflare Origin CA Private Key"
  type        = string
  default     = ""
}

locals {
  use_origin_cert = var.cloudflare_origin_ca_cert != "" && var.cloudflare_origin_ca_key != ""
}
