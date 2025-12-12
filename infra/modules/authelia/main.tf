locals {
  # oci_repo_name      = element(split("/", var.container_repository), length(split("/", var.container_repository)) - 1)
  # oci_image_filename = "${local.oci_repo_name}_${var.container_tag}.tar"
  users_yaml_map = {
    for u in var.authelia_users :
    u.username => {
      displayname = u.display_name
      password    = u.password
      email       = u.email
      groups      = u.groups
    }
  }
  users_yaml = yamlencode(local.users_yaml_map)
}

data "proxmox_virtual_environment_hosts" "target_node" {
  node_name = var.target_node
}

# resource "ansible_playbook" "fetch_template" {
#   playbook   = "./fetch_template_playbook.yaml"
#   replayable = true

#   name = one([
#     for e in data.proxmox_virtual_environment_hosts.target_node.entries :
#     e.address
#     if contains(e.hostnames, var.target_node)
#   ])

#   extra_vars = {
#     ansible_user         = var.ansible_user
#     target_node          = var.target_node
#     template_storage     = var.template_storage
#     oci_image_reference  = "${var.container_repository}:${var.container_tag}"
#     oci_image_filename   = local.oci_image_filename
#   }
# }

resource "proxmox_virtual_environment_oci_image" "authelia" {
  node_name    = var.target_node
  datastore_id = var.template_storage
  reference    = "${var.container_repository}:${var.container_tag}"
}

resource "proxmox_virtual_environment_container" "authelia" {
  node_name    = var.target_node
  vm_id        = var.vmid
  unprivileged = true
  started      = false
  operating_system {
    template_file_id = proxmox_virtual_environment_oci_image.authelia.id
    type             = "ubuntu"
  }

  disk {
    datastore_id = var.rootfs.storage
    size         = var.rootfs.size
  }
  memory {
    dedicated = 1024
    swap      = 512
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
  depends_on = [proxmox_virtual_environment_container.authelia]
  playbook   = "./setup_playbook.yaml"
  replayable = true

  name = one([
    for e in data.proxmox_virtual_environment_hosts.target_node.entries :
    e.address
    if contains(e.hostnames, var.target_node)
  ])

  extra_vars = {
    ansible_user           = var.ansible_user
    local_directory        = "./config/"
    remote_root_path       = "/var/lib/lxc/${var.vmid}/rootfs/"
    vmid                   = var.vmid
    domain                 = var.domain
    authelia_url           = var.authelia_url
    storage_encryption_key = var.storage_encryption_key
    access_control_rules   = yamlencode(var.access_control_rules)
    users_yaml             = local.users_yaml
  }
}
