output "container_id" {
  description = "HomeBox LXC VMID"
  value       = proxmox_virtual_environment_container.homebox.vm_id
}

output "hostname" {
  description = "HomeBox container hostname"
  value       = var.host_name
}

output "ipv4" {
  description = "Detected IPv4 addresses for the HomeBox container"
  value       = proxmox_virtual_environment_container.homebox.ipv4
}

output "data_mount_path_in_datastore" {
  description = "Datastore path for the persistent HomeBox data mount"
  value       = proxmox_virtual_environment_container.homebox.mount_point[0].path_in_datastore
}
