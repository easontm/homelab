variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "chart_version" {
  description = "Version of the Cert-Manager Helm chart to deploy"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy Cert-Manager into"
  type        = string
  default     = "cert-manager"
}
