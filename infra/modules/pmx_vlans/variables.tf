variable "hosts" {
  description = "List of Proxmox hosts to configure VLANs on and their interface names."
  type = list(object({
    hostname       = string
    interface_name = string
    final_octet    = number
  }))
}

variable "vlans" {
  description = "List of VLANs to create on the Proxmox hosts"
  type = list(object({
    id          = number
    description = optional(string, "")
    has_gateway = optional(bool, false)
  }))
}

variable "octet_prefix" {
  description = "The first two octets of the VLAN subnet addresses."
  type        = string
  default     = "10.10"
}
