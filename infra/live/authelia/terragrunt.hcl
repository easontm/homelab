include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  proxmox_vars = read_terragrunt_config(find_in_parent_folders("proxmox.hcl"))
  ansible_vars = read_terragrunt_config(find_in_parent_folders("ansible.hcl"))
  authelia_vars = yamldecode(sops_decrypt_file("./authelia_vars.sops.yaml"))
}

terraform {
  source = "../../modules/authelia"
}

inputs = {
  proxmox_api_url          = local.proxmox_vars.locals.proxmox_api_url
  proxmox_api_token        = local.proxmox_vars.locals.api_token  
  ansible_user              = local.ansible_vars.locals.ansible_user

  target_node               = "pve4"
  vmid                      = 702
  container_repository      = "authelia/authelia"
  container_tag             = "4.39.15"
  template_storage          = "pve-shared"

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
