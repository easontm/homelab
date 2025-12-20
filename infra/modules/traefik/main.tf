data "proxmox_virtual_environment_hosts" "target_node" {
  node_name = var.target_node
}

resource "proxmox_virtual_environment_oci_image" "traefik" {
  node_name    = var.target_node
  datastore_id = var.template_storage
  reference    = "${var.container_repository}:${var.container_tag}"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "traefik_container" {
  node_name    = var.target_node
  vm_id        = var.vmid
  unprivileged = true
  started      = false
  operating_system {
    template_file_id = proxmox_virtual_environment_oci_image.traefik.id
  }

  disk {
    datastore_id = var.rootfs.storage
    size         = var.rootfs.size
  }
  network_interface {
    name     = "eth0"
    firewall = true
    mac_address = var.mac_address
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
  # depends_on = [proxmox_virtual_environment_container.traefik_container]
  playbook   = "./playbook.yaml"
  replayable = true

  name = one([
    for e in data.proxmox_virtual_environment_hosts.target_node.entries :
    e.address
    if contains(e.hostnames, var.target_node)
  ])

  extra_vars = {
    ansible_user       = var.ansible_user
    local_directory    = "./config/"
    remote_root_path   = "/var/lib/lxc/${var.vmid}/rootfs"
    vmid               = var.vmid
    dashboard_enabled  = var.dashboard_enabled
    insecure_dashboard = var.insecure_dashboard
    log_level          = var.log_level
    k8s_gateway_yaml   = local.k8s_gateway_yaml
    k8s_certificate_path = var.k8s_gateway.certAuthFilePath
    k8s_certificate    = var.k8s_gateway.cert
    services_yaml      = local.services_yaml
    middlewares_yaml   = local.middlewares_yaml
    routers_yaml       = local.routers_yaml
  }
}
