output "container_id" {
  description = "HomeBox container VMID"
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

output "postgres_container_id" {
  description = "PostgreSQL OCI container VMID when db_type is postgres"
  value       = try(proxmox_virtual_environment_container.postgres[0].vm_id, null)
}

output "postgres_hostname" {
  description = "PostgreSQL OCI container hostname when db_type is postgres"
  value       = local.postgres_enabled ? local.postgres_host_name : null
}

output "postgres_ipv4" {
  description = "Detected IPv4 addresses for the PostgreSQL OCI container when db_type is postgres"
  value       = try(proxmox_virtual_environment_container.postgres[0].ipv4, null)
}
