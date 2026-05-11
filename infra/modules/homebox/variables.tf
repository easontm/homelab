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

variable "db_type" {
  description = "Database backend for HomeBox. Use sqlite for the default single-container deployment or postgres to provision a separate PostgreSQL OCI container."
  type        = string
  default     = "sqlite"

  validation {
    condition     = contains(["sqlite", "postgres"], var.db_type)
    error_message = "db_type must be either sqlite or postgres."
  }
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

##############
# PostgreSQL
##############
variable "postgres_image" {
  description = "PostgreSQL image reference."
  type        = string
  default     = "docker.io/library/postgres:18"
}

variable "postgres_operating_system_type" {
  description = "Operating system type for the PostgreSQL image. Use alpine when selecting an Alpine-based postgres image tag."
  type        = string
  default     = "debian"
}

variable "postgres_user" {
  description = "PostgreSQL username shared between the PostgreSQL container initialization and HomeBox connection settings."
  type        = string
  default     = "homebox"

  validation {
    condition     = var.db_type != "postgres" || trimspace(var.postgres_user) != ""
    error_message = "postgres_user must not be empty when db_type is postgres."
  }
}

variable "postgres_password" {
  description = "PostgreSQL password shared between the PostgreSQL container initialization and HomeBox connection settings."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.db_type != "postgres" || (var.postgres_password != null && trimspace(var.postgres_password) != "")
    error_message = "postgres_password must be set when db_type is postgres."
  }
}

variable "postgres_database_name" {
  description = "PostgreSQL database name shared between the PostgreSQL container initialization and HomeBox connection settings."
  type        = string
  default     = "homebox"

  validation {
    condition     = var.db_type != "postgres" || trimspace(var.postgres_database_name) != ""
    error_message = "postgres_database_name must not be empty when db_type is postgres."
  }
}

variable "postgres_env_vars" {
  description = "Additional environment variables for the PostgreSQL container, such as PGDATA or POSTGRES_INITDB_ARGS. Shared POSTGRES_* values are derived from typed inputs."
  type        = map(string)
  default     = {}
}

variable "postgres_target_node" {
  description = "Optional Proxmox target node for the PostgreSQL container. Defaults to target_node."
  type        = string
  default     = null
}

variable "postgres_vmid" {
  description = "Optional VMID for the PostgreSQL container. Defaults to vmid + 1."
  type        = number
  default     = null
}

variable "postgres_host_name" {
  description = "Optional hostname for the PostgreSQL container. Defaults to <host_name>-postgres."
  type        = string
  default     = null
}

variable "postgres_description" {
  description = "Optional description for the PostgreSQL container. Defaults to the HomeBox description with a PostgreSQL suffix."
  type        = string
  default     = null
}

variable "postgres_pool_id" {
  description = "Optional Proxmox pool assignment for the PostgreSQL container. Defaults to pool_id."
  type        = string
  default     = null
}

variable "postgres_template_storage" {
  description = "Datastore where the PostgreSQL image template is stored. Defaults to template_storage."
  type        = string
  default     = null
}

variable "postgres_data_mount" {
  description = "Persistent volume mount for PostgreSQL data. Defaults to a 10G volume mounted at /var/lib/postgresql, which matches the postgres:18 image layout."
  type = object({
    storage = string
    size    = string
    path    = string
  })
  default = null
}

variable "postgres_rootfs" {
  description = "Root filesystem configuration for the PostgreSQL container. Defaults to the HomeBox rootfs storage with a larger disk."
  type = object({
    storage = string
    size    = number
  })
  default = null
}

variable "postgres_cpu" {
  description = "CPU configuration for the PostgreSQL container. Defaults to the HomeBox CPU settings."
  type = object({
    architecture = string
    cores        = number
    units        = number
  })
  default = null
}

variable "postgres_memory" {
  description = "Memory configuration for the PostgreSQL container. Defaults to at least 1024 MB plus the HomeBox swap setting."
  type = object({
    dedicated = number
    swap      = number
  })
  default = null
}

variable "postgres_tags" {
  description = "Tags to apply to the PostgreSQL container. Defaults to the HomeBox tags plus postgres."
  type        = list(string)
  default     = null
}

variable "postgres_started" {
  description = "Whether to start the PostgreSQL container after creation. Defaults to started."
  type        = bool
  default     = null
}

variable "postgres_start_on_boot" {
  description = "Automatically start the PostgreSQL container when the host boots. Defaults to start_on_boot."
  type        = bool
  default     = null
}

variable "postgres_unprivileged" {
  description = "Whether the PostgreSQL container should run unprivileged. Defaults to unprivileged."
  type        = bool
  default     = null
}

variable "postgres_wait_for_ipv4" {
  description = "Wait for an IPv4 address after starting the PostgreSQL container. Defaults to wait_for_ipv4."
  type        = bool
  default     = null
}

variable "postgres_network_interface_name" {
  description = "Name for the PostgreSQL container network interface. Defaults to network_interface_name."
  type        = string
  default     = null
}

variable "postgres_network_bridge" {
  description = "Network bridge for the PostgreSQL container. Defaults to network_bridge."
  type        = string
  default     = null
}

variable "postgres_network_firewall" {
  description = "Whether the PostgreSQL interface should use Proxmox firewall rules. Defaults to network_firewall."
  type        = bool
  default     = null
}

variable "postgres_mac_address" {
  description = "MAC address for the PostgreSQL container network interface."
  type        = string
  default     = ""
}

variable "postgres_network_mtu" {
  description = "Optional MTU for the PostgreSQL container network interface. Defaults to network_mtu."
  type        = number
  default     = null
}

variable "postgres_network_vlan_id" {
  description = "Optional VLAN ID for the PostgreSQL container network interface. Defaults to network_vlan_id."
  type        = number
  default     = null
}

variable "postgres_ipv4_address" {
  description = "IPv4 address for the PostgreSQL container. Defaults to dhcp."
  type        = string
  default     = null
}

variable "postgres_gateway_ip" {
  description = "Gateway IP for the PostgreSQL container network configuration. Defaults to gateway_ip when using a static address."
  type        = string
  default     = null
}

variable "postgres_database_host" {
  description = "Hostname or IP address HomeBox should use for PostgreSQL connections. Defaults to the PostgreSQL static IPv4 address when set, otherwise the PostgreSQL hostname."
  type        = string
  default     = null
}
