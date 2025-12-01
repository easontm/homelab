include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  proxmox_vars = read_terragrunt_config(find_in_parent_folders("proxmox.hcl"))
  ansible_vars = read_terragrunt_config(find_in_parent_folders("ansible.hcl"))
}

terraform {
  source = "../../modules/traefik"
}

inputs = {
  proxmox_api_url          = local.proxmox_vars.locals.proxmox_api_url
  proxmox_api_token        = local.proxmox_vars.locals.api_token  
  ansible_user              = local.ansible_vars.locals.ansible_user

  target_node               = "pve4"
  vmid                      = 700
  template_name             = "traefik_v3.6.2.tar"
  template_storage          = "pve-shared"
}
