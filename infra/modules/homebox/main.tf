resource "proxmox_oci_image" "homebox" {
  node_name           = var.target_node
  datastore_id        = var.template_storage
  reference           = "${var.container_repository}:${var.container_tag}"
  overwrite           = true
  overwrite_unmanaged = true
}

# There are some settings here that are specified as the default
# due to a bug in the module
# https://github.com/bpg/terraform-provider-proxmox/issues/2789
resource "proxmox_virtual_environment_container" "homebox" {
  depends_on = [proxmox_virtual_environment_container.postgres]

  description   = var.description
  node_name     = var.target_node
  vm_id         = var.vmid
  pool_id       = var.pool_id
  tags          = var.tags
  started       = var.started
  start_on_boot = var.start_on_boot
  unprivileged  = var.unprivileged

  cpu {
    architecture = var.cpu.architecture
    cores        = var.cpu.cores
    units        = var.cpu.units
  }

  disk {
    datastore_id = var.rootfs.storage
    size         = var.rootfs.size
  }

  mount_point {
    volume = var.data_mount.storage
    size   = var.data_mount.size
    path   = var.data_mount.path
  }

  memory {
    dedicated = var.memory.dedicated
    swap      = var.memory.swap
  }

  network_interface {
    name        = var.network_interface_name
    bridge      = var.network_bridge
    firewall    = var.network_firewall
    mac_address = var.mac_address == "" ? null : var.mac_address
    mtu         = var.network_mtu
    vlan_id     = var.network_vlan_id
  }

  initialization {
    hostname = var.host_name
    # This is the default.
    entrypoint = "/app/api /data/config.yml"

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.gateway_ip
      }
    }
  }

  operating_system {
    template_file_id = proxmox_oci_image.homebox.id
    type             = "alpine"
  }

  environment_variables = merge(
    # These are some more defaults I'm setting here due to the provider bug
    {
      PATH                     = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      HBOX_MODE                = "production"
      HBOX_STORAGE_CONN_STRING = "file:///?no_tmp_dir=true"
      HBOX_STORAGE_PREFIX_PATH = "data"
    },
    local.homebox_database_env,
    try(var.homebox_env_vars, {}),
  )

  wait_for_ip {
    ipv4 = var.started && var.wait_for_ipv4
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "console"
  }
}
