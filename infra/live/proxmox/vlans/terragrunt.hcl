include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "proxmox" {
  path = find_in_parent_folders("proxmox.hcl")
}

locals {
  proxmox_vars = read_terragrunt_config(find_in_parent_folders("proxmox.hcl"))
}

terraform {
  source = "../../../modules/pmx_vlans"
}

inputs = {
  proxmox_api_url          = local.proxmox_vars.locals.proxmox_api_url
  proxmox_api_token        = local.proxmox_vars.locals.api_token  
  hosts = [
    {
      hostname       = "pve1"
      interface_name = "enp4s0"
      final_octet    = 11
    },
    {
      hostname       = "pve3"
      interface_name = "enp3s0"
      final_octet    = 13
    },
    {
      hostname       = "pve4"
      interface_name = "enp3s0"
      final_octet    = 14
    },
    {
      hostname       = "pve5"
      interface_name = "enp3s0"
      final_octet    = 15
    }
  ]
  vlans = [
    {
      id          = 10
      description = "MGMT"
      has_gateway = true
    },
    {
      id          = 20
      description = "STORAGE"
    },
    {
      id          = 30
      description = "SERVERS"
    }
  ]
}
