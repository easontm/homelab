resource "proxmox_virtual_environment_storage_nfs" "nfs_storage" {
  for_each = { for share in var.nfs_shares : share.id => share }

  export  = each.value.export
  id      = each.value.id
  server  = each.value.server
  content = each.value.content
  disable = each.value.disable
  nodes   = each.value.nodes
  options = each.value.options

  dynamic "backups" {
    for_each = each.value.backups != null ? [each.value.backups] : []
    content {
      keep_all              = backups.value.keep_all
      keep_daily            = backups.value.keep_daily
      keep_hourly           = backups.value.keep_hourly
      keep_last             = backups.value.keep_last
      keep_monthly          = backups.value.keep_monthly
      keep_weekly           = backups.value.keep_weekly
      keep_yearly           = backups.value.keep_yearly
      max_protected_backups = backups.value.max_protected_backups
    }
  }
}
