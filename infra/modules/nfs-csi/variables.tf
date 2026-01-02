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

variable "storage_class_name" {
  description = "Name of the StorageClass to be created for NFS CSI"
  type        = string
}

variable "nfs_server" {
  description = "NFS server address"
  type        = string
}

variable "nfs_path" {
  description = "Path on the NFS server to be used for storage"
  type        = string
}

variable "test" {
  description = "Whether to deploy a test pod to verify NFS CSI functionality"
  type        = bool
  default     = false
}
