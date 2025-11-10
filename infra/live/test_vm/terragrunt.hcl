terraform {
    source = "../../modules/vm"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  proxmox_vars = read_terragrunt_config(find_in_parent_folders("proxmox.hcl"))
}

inputs = {
  proxmox_api_url          = local.proxmox_vars.locals.proxmox_api_url
  proxmox_api_token_id     = local.proxmox_vars.locals.proxmox_user
  proxmox_api_token_secret = local.proxmox_vars.locals.proxmox_pass
}