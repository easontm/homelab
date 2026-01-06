variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "chart_version" {
  description = "Version of the metrics-server Helm chart to deploy"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy metrics-server into"
  type        = string
  default     = "kube-system"
}
