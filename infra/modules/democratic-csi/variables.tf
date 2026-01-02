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

variable "truenas_host" {
  description = "Name of the StorageClass to be created for NFS CSI"
  type        = string
}

variable "truenas_api_key" {
  description = "API key for TrueNAS access"
  type        = string
}

variable "volume_path" {
  description = "Path on TrueNAS for volume storage"
  type        = string
}

variable "snapshot_path" {
  description = "Path on TrueNAS for snapshot storage"
  type        = string
}

variable "portal_group_id" {
  description = "ID of the Portal Group in TrueNAS"
  type        = number
}
variable "initiator_group_id" {
  description = "ID of the Initiator Group in TrueNAS"
  type        = number
}
