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

variable "authelia_protected_namespaces" {
  type    = set(string)
  default = ["paperless-ngx"] 
}
