# data "proxmox_virtual_environment_hosts" "target_node" {
#   node_name = var.target_node
# }


# resource "proxmox_virtual_environment_oci_image" "cloudflared" {
#   node_name    = var.target_node
#   datastore_id = var.template_storage
#   reference    = "${var.container_repository}:${var.container_tag}"
# }

# resource "proxmox_virtual_environment_container" "cloudflared" {
#   node_name    = var.target_node
#   vm_id        = var.vmid
#   unprivileged = true
#   started      = false
#   operating_system {
#     template_file_id = proxmox_virtual_environment_oci_image.cloudflared.id
#     type             = "ubuntu"
#   }

#   disk {
#     datastore_id = var.rootfs.storage
#     size         = var.rootfs.size
#   }
#   memory {
#     dedicated = 1024
#     swap      = 512
#   }
#   network_interface {
#     name     = "eth0"
#     firewall = true
#   }
#   initialization {
#     hostname = var.host_name

#     ip_config {
#       ipv4 {
#         address = "dhcp"
#       }
#     }
#   }
# }
