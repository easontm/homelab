include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "proxmox" {
  path           = find_in_parent_folders("proxmox.hcl")
  expose         = true
  merge_strategy = "deep"
}

locals {
  ansible_vars = read_terragrunt_config(find_in_parent_folders("ansible.hcl"))
  authelia_vars = yamldecode(sops_decrypt_file("./authelia_vars.sops.yaml"))
}

terraform {
  source = "../../../modules/authelia"
}

inputs = {
  ansible_user              = local.ansible_vars.locals.ansible_user

  target_node               = "pve4"
  vmid                      = 702
  container_repository      = "authelia/authelia"
  container_tag             = "4.39.15"
  template_storage          = "pve-shared"
  mac_address               = "bc:24:11:91:2f:d9"

  domain = local.authelia_vars.domain
  authelia_url = local.authelia_vars.authelia_url
  storage_encryption_key = local.authelia_vars.storage_encryption_key
  access_control_rules = [
    {
      domain = "*.${local.authelia_vars.domain}"
      policy = "one_factor"
    }
  ]

  authelia_users = local.authelia_vars.users
}
