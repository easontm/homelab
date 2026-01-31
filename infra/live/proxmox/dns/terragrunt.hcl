include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "proxmox" {
  path   = find_in_parent_folders("proxmox.hcl")
  expose = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../modules/pmx_dns"
}

locals {
  domain = "lab.home"
  nodes = ["pve1", "pve3", "pve4", "pve5"]
  servers = ["10.10.10.1"]
}

inputs = {
  dns_configs = [
    for node in local.nodes : {
      node_name = node
      domain    = local.domain
      servers   = local.servers
    }
  ]
}
