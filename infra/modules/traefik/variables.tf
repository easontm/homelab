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
  default     = "traefik"
}

variable "template_storage" {
  description = "Datastore where the LXC template is stored"
  type        = string
}

variable "template_name" {
  description = "Name of the LXC template file"
  type        = string
  default     = "traefik_v3.6.2.tar"
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