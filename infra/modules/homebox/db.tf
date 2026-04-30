locals {
  postgres_enabled = var.db_type == "postgres"

  postgres_target_node = coalesce(var.postgres_target_node, var.target_node)
  postgres_vmid        = coalesce(var.postgres_vmid, var.vmid + 1)
  postgres_host_name   = coalesce(var.postgres_host_name, "${var.host_name}-postgres")
  postgres_description = coalesce(var.postgres_description, "${var.description} (PostgreSQL)")
  postgres_pool_id     = try(coalesce(var.postgres_pool_id, var.pool_id), null)

  postgres_template_storage = coalesce(var.postgres_template_storage, var.template_storage)

  postgres_rootfs = var.postgres_rootfs != null ? var.postgres_rootfs : {
    storage = var.rootfs.storage
    size    = max(var.rootfs.size, 8)
  }

  postgres_cpu = var.postgres_cpu != null ? var.postgres_cpu : var.cpu

  postgres_memory = var.postgres_memory != null ? var.postgres_memory : {
    dedicated = max(var.memory.dedicated, 1024)
    swap      = var.memory.swap
  }

  postgres_tags              = var.postgres_tags != null ? var.postgres_tags : distinct(concat(var.tags, ["postgres"]))
  postgres_started           = coalesce(var.postgres_started, var.started)
  postgres_start_on_boot     = coalesce(var.postgres_start_on_boot, var.start_on_boot)
  postgres_unprivileged      = coalesce(var.postgres_unprivileged, var.unprivileged)
  postgres_wait_for_ipv4     = coalesce(var.postgres_wait_for_ipv4, var.wait_for_ipv4)
  postgres_interface_name    = coalesce(var.postgres_network_interface_name, var.network_interface_name)
  postgres_network_bridge    = coalesce(var.postgres_network_bridge, var.network_bridge)
  postgres_network_firewall  = coalesce(var.postgres_network_firewall, var.network_firewall)
  postgres_network_mtu       = try(coalesce(var.postgres_network_mtu, var.network_mtu), null)
  postgres_network_vlan_id   = try(coalesce(var.postgres_network_vlan_id, var.network_vlan_id), null)
  postgres_ipv4_address      = coalesce(var.postgres_ipv4_address, "dhcp")
  postgres_gateway_ip        = coalesce(var.postgres_gateway_ip, var.gateway_ip)
  postgres_static_host       = local.postgres_ipv4_address == "dhcp" ? null : split("/", local.postgres_ipv4_address)[0]
  postgres_connection_target = coalesce(var.postgres_database_host, local.postgres_static_host, local.postgres_host_name)

  homebox_database_env = local.postgres_enabled ? {
    HBOX_DATABASE_DRIVER = "postgres"
    HBOX_DATABASE_HOST   = local.postgres_connection_target
    HBOX_DATABASE_PORT   = "5432"
    } : {
    HBOX_DATABASE_SQLITE_PATH = "/data/homebox.db?_pragma=busy_timeout=2000&_pragma=journal_mode=WAL&_fk=1&_time_format=sqlite"
  }
}

resource "proxmox_download_file" "postgres_template" {
  count = local.postgres_enabled ? 1 : 0

  content_type        = "vztmpl"
  datastore_id        = local.postgres_template_storage
  file_name           = var.postgres_template_file_name
  node_name           = local.postgres_target_node
  url                 = var.postgres_template_url
  checksum            = var.postgres_template_checksum
  checksum_algorithm  = var.postgres_template_checksum_algorithm
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "postgres" {
  count = local.postgres_enabled ? 1 : 0

  description   = local.postgres_description
  node_name     = local.postgres_target_node
  vm_id         = local.postgres_vmid
  pool_id       = local.postgres_pool_id
  tags          = local.postgres_tags
  started       = local.postgres_started
  start_on_boot = local.postgres_start_on_boot
  unprivileged  = local.postgres_unprivileged

  cpu {
    architecture = local.postgres_cpu.architecture
    cores        = local.postgres_cpu.cores
    units        = local.postgres_cpu.units
  }

  disk {
    datastore_id = local.postgres_rootfs.storage
    size         = local.postgres_rootfs.size
  }

  memory {
    dedicated = local.postgres_memory.dedicated
    swap      = local.postgres_memory.swap
  }

  network_interface {
    name        = local.postgres_interface_name
    bridge      = local.postgres_network_bridge
    firewall    = local.postgres_network_firewall
    mac_address = var.postgres_mac_address == "" ? null : var.postgres_mac_address
    mtu         = local.postgres_network_mtu
    vlan_id     = local.postgres_network_vlan_id
  }

  initialization {
    hostname = local.postgres_host_name

    ip_config {
      ipv4 {
        address = local.postgres_ipv4_address
        gateway = local.postgres_ipv4_address == "dhcp" ? null : local.postgres_gateway_ip
      }
    }
  }

  operating_system {
    template_file_id = proxmox_download_file.postgres_template[0].id
    type             = "debian"
  }

  wait_for_ip {
    ipv4 = local.postgres_started && local.postgres_wait_for_ipv4
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "console"
  }
}
