locals {
  host_vlan_matrix = flatten([
    for host in var.hosts : [
      for vlan in var.vlans : {
        hostname    = host.hostname
        interface   = host.interface_name
        final_octet = host.final_octet
        vlan_id     = vlan.id
        vlan_desc   = vlan.description
        has_gateway = vlan.has_gateway
      }
    ]
  ])
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlan" {
  for_each  = { for combo in local.host_vlan_matrix : "${combo.hostname}-${combo.vlan_id}" => combo }
  node_name = each.value.hostname
  name      = "${each.value.interface}.${each.value.vlan_id}"
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr" {
  for_each = { for combo in local.host_vlan_matrix : "${combo.hostname}-${combo.vlan_id}" => combo }
  depends_on = [
    proxmox_virtual_environment_network_linux_vlan.vlan
  ]
  node_name  = each.value.hostname
  name       = "vmbr${each.value.vlan_id}"
  address    = "${var.octet_prefix}.${each.value.vlan_id}.${each.value.final_octet}/24"
  gateway    = each.value.has_gateway ? "${var.octet_prefix}.${each.value.vlan_id}.1" : null
  comment    = each.value.vlan_desc
  ports      = ["${each.value.interface}.${each.value.vlan_id}"]
  vlan_aware = false
}

