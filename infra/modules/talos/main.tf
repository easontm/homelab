data "proxmox_virtual_environment_file" "talos_disk" {
  node_name    = var.talos_disk_node_name
  datastore_id = var.vm_disk_datastore_id
  content_type = "import"
  file_name    = var.talos_disk_file_name
}

locals {
  talos_nodes = merge(
    var.node_data.controlplanes,
    var.node_data.workers
  )
}

resource "proxmox_virtual_environment_vm" "talos_vms" {
  for_each  = local.talos_nodes
  name      = each.value.hostname != null ? each.value.hostname : "talos-${each.key}"
  node_name = each.value.pve_node
  tags      = var.vm_tags
  vm_id     = each.value.vmid
  started   = true
  machine   = "q35"

  agent {
    enabled = true
    type    = "virtio"
  }
  operating_system {
    type = "l26"
  }
  cpu {
    cores = lookup(each.value, "cpu_cores", var.default_cpu_cores)
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = lookup(each.value, "memory_mb", var.default_memory_mb)
  }
  disk {
    datastore_id = var.vm_disk_datastore_id
    import_from  = data.proxmox_virtual_environment_file.talos_disk.id
    interface    = "virtio0"
    iothread     = true
    size         = lookup(each.value, "disk_size_gb", var.default_disk_size_gb)
    backup       = false
    discard      = "on"
  }

  network_device {
    disconnected = false
    firewall     = true
    bridge       = var.vm_network_bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.key}/24"
        gateway = var.gateway_ip
      }
    }
  }
}
