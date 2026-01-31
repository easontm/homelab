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
  source = "../../../modules/pmx_nfs"
}

inputs = {
  proxmox_api_url   = local.proxmox_vars.locals.proxmox_api_url
  proxmox_api_token = local.proxmox_vars.locals.api_token  

  nfs_shares = [
    {
      export = "/mnt/volume1/proxmox/pve-shared"
      id     = "pve-shared"
      server = "10.10.20.2"
      content = toset(["images", "iso", "vztmpl", "rootdir", "snippets", "import"])
    },
    {
      export = "/mnt/volume1/proxmox/pve-backups"
      id     = "pve-backups"
      server = "10.10.20.2"
      content = toset(["backup"])
    }
  ]
}
