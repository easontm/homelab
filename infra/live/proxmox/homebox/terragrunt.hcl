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
  target_node      = "pve4"
  vmid             = 703
  host_name        = "homebox"
  template_storage = "pve-shared"
  network_bridge   = "vmbr30"
  ipv4_address     = "10.10.30.3/24"
  gateway_ip       = "10.10.30.1"

  container_tag = try(local.homebox_vars.container_tag, "latest")

  homebox_config = merge(
    {
      options_trust_proxy = true
      options_hostname    = try(local.homebox_vars.public_hostname, null)
    },
    try(local.homebox_vars.homebox_config, {}),
  )

  homebox_environment_overrides = try(local.homebox_vars.environment_overrides, {})
}
