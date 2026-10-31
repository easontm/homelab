variable "kubeconfig_paths" {
  description = "Kubeconfig paths, in precedence order, for the target cluster."
  type        = list(string)
}

variable "bundle" {
  description = "Vendored API bundle directory under manifests/. Versions are explicit and independent of the controller."
  type        = string

  validation {
    condition     = contains(["gateway-api/1.6.3-standard", "traefik/42.1.3"], var.bundle)
    error_message = "Select a reviewed, vendored bundle: gateway-api/1.6.3-standard or traefik/42.1.3."
  }
}

variable "force_conflicts_for" {
  description = "Temporary ownership-transfer allowlist of Kind/name keys. Use only for reviewed adoption from a prior manager, then return to the empty default."
  type        = set(string)
  default     = []
}
