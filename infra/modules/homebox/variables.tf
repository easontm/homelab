##############
# Global
##############
variable "target_node" {
  description = "Proxmox target node"
  type        = string
}

variable "vmid" {
  description = "VMID for the container"
  type        = number
}

variable "container_repository" {
  description = "OCI container repository"
  type        = string
  default     = "ghcr.io/sysadminsmedia/homebox"
}

variable "container_tag" {
  description = "OCI container tag"
  type        = string
  default     = "latest"
}

variable "description" {
  description = "Description for the LXC container"
  type        = string
  default     = "Managed by Terraform"
}

variable "pool_id" {
  description = "Optional Proxmox pool assignment"
  type        = string
  default     = null
}

##############
# Container
##############
variable "host_name" {
  description = "Hostname for the LXC container"
  type        = string
  default     = "homebox"
}

variable "template_storage" {
  description = "Datastore where the OCI image template is stored"
  type        = string
}

variable "rootfs" {
  description = "Root filesystem configuration for the LXC container"
  type = object({
    storage = string
    size    = number
  })
  default = {
    storage = "local-lvm"
    size    = 4
  }
}

variable "data_mount" {
  description = "Persistent volume mount for HomeBox application data"
  type = object({
    storage = string
    size    = string
    path    = string
  })
  default = {
    storage = "local-lvm"
    size    = "10G"
    path    = "/data"
  }
}

variable "cpu" {
  description = "CPU configuration for the LXC container"
  type = object({
    architecture = string
    cores        = number
    units        = number
  })
  default = {
    architecture = "amd64"
    cores        = 1
    units        = 1024
  }
}

variable "memory" {
  description = "Memory configuration for the LXC container"
  type = object({
    dedicated = number
    swap      = number
  })
  default = {
    dedicated = 1024
    swap      = 512
  }
}

variable "tags" {
  description = "Tags to apply to the LXC container"
  type        = list(string)
  default     = ["container", "homebox"]
}

variable "started" {
  description = "Whether to start the container after creation"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Automatically start the container when the host boots"
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Whether the container should run unprivileged"
  type        = bool
  default     = true
}

variable "wait_for_ipv4" {
  description = "Wait for an IPv4 address after starting the container"
  type        = bool
  default     = true
}

##############
# Networking
##############
variable "network_interface_name" {
  description = "Name for the container network interface"
  type        = string
  default     = "eth0"
}

variable "network_bridge" {
  description = "Network bridge for the container"
  type        = string
  default     = "vmbr0"
}

variable "network_firewall" {
  description = "Whether the interface should use Proxmox firewall rules"
  type        = bool
  default     = true
}

variable "mac_address" {
  description = "MAC address for the container network interface"
  type        = string
  default     = ""
}

variable "network_mtu" {
  description = "Optional MTU for the container network interface"
  type        = number
  default     = null
}

variable "network_vlan_id" {
  description = "Optional VLAN ID for the container network interface"
  type        = number
  default     = null
}

variable "ipv4_address" {
  description = "IPv4 address for the container. Can be set to dhcp."
  type        = string
  default     = "dhcp"
}

variable "gateway_ip" {
  description = "Gateway IP for the container network configuration. Omit when using DHCP."
  type        = string
  default     = null
}

##############
# HomeBox configuration
##############
variable "homebox_env_vars" {
  description = "HomeBox environment variables passed directly to the container. Keys should match HBOX_* envvar names expected by the application."
  type        = map(string)
  default     = {}
}
