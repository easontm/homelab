# Documentation for these values is here
# https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_dns

# Required
# node_name (String) The name of the node.

# Optional
# domain (String) The DNS search domain.
# servers (List of String) The list of DNS servers.

variable "dns_configs" {
  description = "List of DNS configurations for Proxmox nodes."
  type = list(object({
    node_name = string
    domain    = optional(string)
    servers   = optional(list(string), [])
  }))
  default = []
}
