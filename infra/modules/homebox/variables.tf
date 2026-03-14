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

variable "entrypoint" {
  description = "Optional container init command override"
  type        = string
  default     = null
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
variable "homebox_config" {
  description = "HomeBox settings mapped to common HBOX_* environment variables"
  type = object({
    mode                            = optional(string, "production")
    web_port                        = optional(number, 7745)
    web_host                        = optional(string)
    web_max_upload_size             = optional(number, 10)
    web_read_timeout                = optional(string, "10s")
    web_write_timeout               = optional(string, "10s")
    web_idle_timeout                = optional(string, "30s")
    storage_conn_string             = optional(string, "file:///?no_tmp_dir=true")
    storage_prefix_path             = optional(string, "data")
    log_level                       = optional(string, "info")
    log_format                      = optional(string, "text")
    database_driver                 = optional(string, "sqlite3")
    database_sqlite_path            = optional(string, "/data/homebox.db?_pragma=busy_timeout=2000&_pragma=journal_mode=WAL&_fk=1&_time_format=sqlite")
    database_pub_sub_conn_string    = optional(string, "mem://{{ .Topic }}")
    options_allow_registration      = optional(bool, true)
    options_auto_increment_asset_id = optional(bool, true)
    options_allow_analytics         = optional(bool, false)
    options_github_release_check    = optional(bool, true)
    options_allow_local_login       = optional(bool, true)
    options_trust_proxy             = optional(bool, false)
    options_hostname                = optional(string)
    auth_rate_limit_enabled         = optional(bool, true)
    auth_rate_limit_max_attempts    = optional(number, 5)
    auth_rate_limit_window          = optional(string, "1m")
    auth_rate_limit_base_backoff    = optional(string, "10s")
    auth_rate_limit_max_backoff     = optional(string, "5m")
    debug_enabled                   = optional(bool, false)
    debug_port                      = optional(number, 4000)
    demo                            = optional(bool, false)
    oidc_enabled                    = optional(bool, false)
    oidc_issuer_url                 = optional(string)
    oidc_client_id                  = optional(string)
    oidc_client_secret              = optional(string)
    oidc_scope                      = optional(string, "openid profile email")
    oidc_allowed_groups             = optional(string)
    oidc_auto_redirect              = optional(bool, false)
    oidc_verify_email               = optional(bool, false)
    oidc_group_claim                = optional(string, "groups")
    oidc_email_claim                = optional(string, "email")
    oidc_name_claim                 = optional(string, "name")
    oidc_email_verified_claim       = optional(string, "email_verified")
    oidc_button_text                = optional(string, "Sign in with OIDC")
    oidc_state_expiry               = optional(string, "10m")
    oidc_request_timeout            = optional(string, "30s")
    mailer_host                     = optional(string)
    mailer_port                     = optional(number, 587)
    mailer_username                 = optional(string)
    mailer_password                 = optional(string)
    mailer_from                     = optional(string)
    thumbnail_enabled               = optional(bool, true)
    thumbnail_width                 = optional(number, 500)
    thumbnail_height                = optional(number, 500)
  })
  default = {}
}

variable "homebox_environment_overrides" {
  description = "Additional raw HBOX_* environment variable overrides for advanced HomeBox settings"
  type        = map(string)
  default     = {}
}
