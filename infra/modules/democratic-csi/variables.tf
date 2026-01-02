variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "snapshot_controller_namespace" {
  description = "Kubernetes namespace where the snapshot-controller will be deployed"
  type        = string
  default     = "kube-system"
}

variable "snapshot_chart_version" {
  description = "Version of the snapshot-controller Helm chart to deploy"
  type        = string
}

variable "csi_namespace" {
  description = "Kubernetes namespace where the democratic-csi driver will be deployed"
  type        = string
  default     = "democratic-csi"
}

variable "csi_chart_version" {
  description = "Version of the democratic-csi Helm chart to deploy"
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

variable "storage_class_name" {
  description = "Name of the StorageClass to be created for test PVC"
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

variable "test" {
  description = "Enable to create a test PVC"
  type        = bool
  default     = false
}
