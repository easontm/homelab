##############
# Global
##############
variable "target_node" {
  description = "Proxmox Target Node"
  type        = string
}

variable "vmid" {
  description = "VMID for the container"
  type        = number
}

variable "container_repository" {
  description = "OCI Container Repository"
  type        = string
}

variable "container_tag" {
  description = "OCI Container Tag"
  type        = string
  default     = "latest"
}

##############
# Ansible
##############
variable "ansible_user" {
  description = "Ansible user for remote connection"
  type        = string
  default     = "ansible"
}

##############
# Container
##############

variable "host_name" {
  description = "Hostname for the LXC container"
  type        = string
  default     = "authelia"
}

variable "template_storage" {
  description = "Datastore where the LXC template is stored"
  type        = string
}

variable "rootfs" {
  description = "Root filesystem configuration for the LXC container"
  type = object({
    storage = string
    size    = string
  })
  default = {
    storage = "local-lvm"
    size    = "4"
  }
}

##############
# Authelia
##############

variable "domain" {
  description = "Domain for Authelia configuration"
  type        = string
}

variable "authelia_url" {
  description = "URL for Authelia service"
  type        = string
}

variable "storage_encryption_key" {
  description = "Encryption key for Authelia storage"
  type        = string
}

variable "access_control_rules" {
  description = "Access control rules for Authelia"
  type = list(object({
    domain : string
    policy : string
    resources : optional(map(list(string)))
    methods : optional(map(list(string)))
  }))
  default = []
}

variable "authelia_users" {
  description = "List of Authelia users"
  type = list(object({
    username : string
    password : string
    display_name : string
    email : string
    groups : list(string)
  }))
  default = []
}
