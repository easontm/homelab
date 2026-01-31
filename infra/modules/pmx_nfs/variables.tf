# Documentation for these values is here
# https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_storage_nfs

# Required
# export (String) The path of the NFS export.
# id (String) The unique identifier of the storage.
# server (String) The IP address or DNS name of the NFS server.

# Optional
# backups (Block, Optional) Configure backup retention settings for the storage type. (see below for nested schema)
# content (Set of String) The content types that can be stored on this storage.
#   Valid values are:
#       Disk image (images)
#       ISO image (iso)
#       Container template (vztmpl)
#       Backup (backup)
#       Container (rootdir)
#       Snippets (snippets)
#       Import (import)
# disable (Boolean) Whether the storage is disabled.
# nodes (Set of String) A list of nodes where this storage is available.
# options (String) The options to pass to the NFS service.
# preallocation (String) The preallocation mode for raw and qcow2 images.
# snapshot_as_volume_chain (Boolean) Enable support for creating snapshots through volume backing-chains.

# Nested Schema for backups
# Optional:
# keep_all (Boolean) Specifies if all backups should be kept, regardless of their age. When set to true, other keep_* attributes must not be set.
# keep_daily (Number) The number of daily backups to keep. Older backups will be removed.
# keep_hourly (Number) The number of hourly backups to keep. Older backups will be removed.
# keep_last (Number) Specifies the number of the most recent backups to keep, regardless of their age.
# keep_monthly (Number) The number of monthly backups to keep. Older backups will be removed.
# keep_weekly (Number) The number of weekly backups to keep. Older backups will be removed.
# keep_yearly (Number) The number of yearly backups to keep. Older backups will be removed.
# max_protected_backups (Number) The maximum number of protected backups per guest. Use '-1' for unlimited.

variable "nfs_shares" {
  description = "List of NFS shares to create in Proxmox."
  type = list(object({
    export  = string
    id      = string
    server  = string
    content = set(string)
    disable = optional(bool, false)
    nodes   = optional(set(string), [])
    backups = optional(object({
      keep_all              = optional(bool)
      keep_daily            = optional(number)
      keep_hourly           = optional(number)
      keep_last             = optional(number)
      keep_monthly          = optional(number)
      keep_weekly           = optional(number)
      keep_yearly           = optional(number)
      max_protected_backups = optional(number)
    }))
  }))
  default = []
}
