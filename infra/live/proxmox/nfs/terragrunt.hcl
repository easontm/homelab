include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "proxmox" {
  path           = find_in_parent_folders("proxmox.hcl")
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../modules/pmx_nfs"
}

inputs = {
  nfs_shares = [
    {
      export  = "/mnt/volume1/proxmox/pve-shared"
      id      = "pve-shared"
      server  = "10.10.20.2"
      content = toset(["images", "iso", "vztmpl", "rootdir", "snippets", "import"])
      options = "vers=4.2"
    },
    {
      export  = "/mnt/volume1/proxmox/pve-backups"
      id      = "pve-backups"
      server  = "10.10.20.2"
      content = toset(["backup"])
      options = "vers=4.2"
    }
  ]
}
