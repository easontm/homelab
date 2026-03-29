variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "chart_version" {
  description = "Version of the Velero Helm chart to deploy"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy Velero into"
  type        = string
  default     = "velero"
}

variable "key_id" {
  description = "AWS Access Key ID for Velero to use"
  type        = string
}

variable "secret_key" {
  description = "AWS Secret Access Key for Velero to use"
  type        = string
}
