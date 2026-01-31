resource "proxmox_virtual_environment_dns" "dns" {
  for_each = { for config in var.dns_configs : config.node_name => config }

  node_name = each.value.node_name
  domain    = each.value.domain
  servers   = each.value.servers
}
