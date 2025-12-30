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

variable "traefik_granted_namespaces" {
  type    = set(string)
  default = []
}

variable "authelia_service_url" {
  description = "URL of the Authelia service for forward authentication"
  type        = string
  default     = ""
}

#################
# Cert Manager
#################
variable "common_name" {
  description = "Common name for the TLS certificate"
  type        = string
}
variable "dns_names" {
  description = "DNS names for the TLS certificate"
  type        = list(string)
}
