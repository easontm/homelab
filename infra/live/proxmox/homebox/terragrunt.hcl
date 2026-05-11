include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "proxmox" {
  path           = find_in_parent_folders("proxmox.hcl")
  expose         = true
  merge_strategy = "deep"
}

locals {
  homebox_vars = fileexists("./homebox_vars.sops.yaml") ? yamldecode(sops_decrypt_file("./homebox_vars.sops.yaml")) : {}
}

terraform {
  source = "../../../modules/homebox"
}

inputs = {
  target_node      = "pve3"
  vmid             = 600
  host_name        = "homebox"
  template_storage = "pve-shared"
  network_bridge   = "vmbr30"
  ipv4_address     = "10.10.30.3/24"
  gateway_ip       = "10.10.30.1"

  container_tag = "0.25.0"

  db_type                 = "postgres"
  postgres_network_bridge = "vmbr20"
  postgres_ipv4_address   = try(local.homebox_vars.postgres_ipv4_address, "10.10.20.3/24")
  postgres_gateway_ip     = try(local.homebox_vars.postgres_gateway_ip, "10.10.20.1")

  

  postgres_template_storage      = try(local.homebox_vars.postgres_template_storage, null)
  postgres_data_mount            = try(local.homebox_vars.postgres_data_mount, null)
  postgres_user              = try(local.homebox_vars.postgres_user, "homebox")
  postgres_password          = try(local.homebox_vars.postgres_password, "testpass")
  postgres_database_name     = try(local.homebox_vars.postgres_database_name, "homebox")
  postgres_vmid              = try(local.homebox_vars.postgres_vmid, null)
  postgres_host_name         = try(local.homebox_vars.postgres_host_name, null)
  postgres_database_host     = try(local.homebox_vars.postgres_database_host, null)
  postgres_env_vars          = try(local.homebox_vars.postgres_env_vars, {})

  homebox_env_vars = merge(
    {
      HBOX_OPTIONS_TRUST_PROXY = "true"
      HBOX_DATABASE_SSL_MODE  = "disable"
    },
    try(local.homebox_vars.public_hostname, null) != null ? {
      HBOX_OPTIONS_HOSTNAME = local.homebox_vars.public_hostname
    } : {},
    try(local.homebox_vars.homebox_env_vars, {}),
  )
}
