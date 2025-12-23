variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "chart_version" {
  description = "Version of the MetalLB Helm chart to deploy"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy MetalLB into"
  type        = string
  default     = "metallb-system"
}

variable "ip_ranges" {
  description = "List of IP ranges MetalLB can use to expose services"
  type        = list(string)
  default     = []
}
