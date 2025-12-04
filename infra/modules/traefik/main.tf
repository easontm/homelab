data "proxmox_virtual_environment_datastores" "available_storages" {
  node_name = var.target_node
  filters = {
    id = var.template_storage
  }
}

data "proxmox_virtual_environment_hosts" "target_node" {
  node_name = var.target_node
}

resource "proxmox_virtual_environment_container" "traefik_container" {
  node_name    = var.target_node
  vm_id        = var.vmid
  unprivileged = true
  started      = false
  operating_system {
    template_file_id = "${data.proxmox_virtual_environment_datastores.available_storages.datastores[0].id}:vztmpl/${var.template_name}"
  }

  disk {
    datastore_id = var.rootfs.storage
    size         = var.rootfs.size
  }
  network_interface {
    name     = "eth0"
    firewall = true
  }
  initialization {
    hostname = var.host_name

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

resource "ansible_playbook" "setup" {
  depends_on = [proxmox_virtual_environment_container.traefik_container]
  playbook   = "./playbook.yaml"
  replayable = false

  name = one([
    for e in data.proxmox_virtual_environment_hosts.target_node.entries :
    e.address
    if contains(e.hostnames, var.target_node)
  ])

  extra_vars = {
    ansible_user    = var.ansible_user
    local_directory = "./config/"
    remote_etc_path = "/var/lib/lxc/${var.vmid}/rootfs/etc"
    vmid            = var.vmid
  }
}
