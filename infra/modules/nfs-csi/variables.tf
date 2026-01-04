variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Kubernetes namespace where the NFS CSI driver will be deployed"
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Version of the NFS CSI Helm chart to deploy"
  type        = string
}

variable "storage_classes" {
  description = "List of storage classes to create for NFS CSI"
  type = list(object({
    name                   = string
    nfs_server             = string
    nfs_path               = string
    is_default             = optional(bool, false)
    reclaim_policy         = optional(string, "Retain")
    volume_binding_mode    = optional(string, "Immediate")
    allow_volume_expansion = optional(bool, true)
    mount_options          = optional(list(string), ["nfsvers=4.1", "hard", "noatime"])
  }))
  default = []
}

variable "test" {
  description = "Whether to deploy a test pod to verify NFS CSI functionality"
  type        = bool
  default     = false
}
