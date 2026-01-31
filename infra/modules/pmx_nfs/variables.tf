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
