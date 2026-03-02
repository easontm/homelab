variable "talos_disk_node_name" {
  description = "Node name for the Talos disk import."
  type        = string
}

variable "talos_disk_file_name" {
  description = "Talos disk file name for import."
  type        = string
}


variable "vm_tags" {
  description = "Tags for the base VM."
  type        = list(string)
  default     = ["terraform", "k8s"]
}

variable "default_cpu_cores" {
  description = "Number of CPU cores for the base VM."
  type        = number
  default     = 2
}

variable "default_memory_mb" {
  description = "Dedicated memory size (MB) for the base VM."
  type        = number
  default     = 2048
}

variable "default_disk_size_gb" {
  description = "Disk size (GB) for the base VM."
  type        = number
  default     = 40
}

variable "vm_disk_datastore_id" {
  description = "Datastore ID for the base VM disk."
  type        = string
}

variable "vm_network_bridge" {
  description = "Network bridge for the base VM."
  type        = string
}

variable "gateway_ip" {
  description = "Gateway IP for the Talos cluster."
  type        = string
}

variable "talos_version" {
  description = "Talos version to use for the cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster."
  type        = string
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      pve_node         = string
      vmid             = number
      install_disk     = string
      hostname         = string
      cpu_cores        = optional(number)
      memory_mb        = optional(number)
      disk_size_gb     = optional(number)
      kernels          = optional(list(string), [])
      allow_scheduling = optional(bool, false)
    }))
    workers = map(object({
      pve_node     = string
      vmid         = number
      install_disk = string
      hostname     = string
      cpu_cores    = optional(number)
      memory_mb    = optional(number)
      disk_size_gb = optional(number)
      kernels      = optional(list(string), [])
    }))
  })
}
