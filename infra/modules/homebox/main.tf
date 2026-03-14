locals {
  homebox_environment_defaults = {
    HBOX_MODE                            = var.homebox_config.mode
    HBOX_WEB_PORT                        = tostring(var.homebox_config.web_port)
    HBOX_WEB_HOST                        = var.homebox_config.web_host
    HBOX_WEB_MAX_UPLOAD_SIZE             = tostring(var.homebox_config.web_max_upload_size)
    HBOX_WEB_READ_TIMEOUT                = var.homebox_config.web_read_timeout
    HBOX_WEB_WRITE_TIMEOUT               = var.homebox_config.web_write_timeout
    HBOX_WEB_IDLE_TIMEOUT                = var.homebox_config.web_idle_timeout
    HBOX_STORAGE_CONN_STRING             = var.homebox_config.storage_conn_string
    HBOX_STORAGE_PREFIX_PATH             = var.homebox_config.storage_prefix_path
    HBOX_LOG_LEVEL                       = var.homebox_config.log_level
    HBOX_LOG_FORMAT                      = var.homebox_config.log_format
    HBOX_MAILER_HOST                     = var.homebox_config.mailer_host
    HBOX_MAILER_PORT                     = tostring(var.homebox_config.mailer_port)
    HBOX_MAILER_USERNAME                 = var.homebox_config.mailer_username
    HBOX_MAILER_PASSWORD                 = var.homebox_config.mailer_password
    HBOX_MAILER_FROM                     = var.homebox_config.mailer_from
    HBOX_DATABASE_DRIVER                 = var.homebox_config.database_driver
    HBOX_DATABASE_SQLITE_PATH            = var.homebox_config.database_sqlite_path
    HBOX_DATABASE_PUB_SUB_CONN_STRING    = var.homebox_config.database_pub_sub_conn_string
    HBOX_OPTIONS_ALLOW_REGISTRATION      = tostring(var.homebox_config.options_allow_registration)
    HBOX_OPTIONS_AUTO_INCREMENT_ASSET_ID = tostring(var.homebox_config.options_auto_increment_asset_id)
    HBOX_OPTIONS_ALLOW_ANALYTICS         = tostring(var.homebox_config.options_allow_analytics)
    HBOX_OPTIONS_GITHUB_RELEASE_CHECK    = tostring(var.homebox_config.options_github_release_check)
    HBOX_OPTIONS_ALLOW_LOCAL_LOGIN       = tostring(var.homebox_config.options_allow_local_login)
    HBOX_OPTIONS_TRUST_PROXY             = tostring(var.homebox_config.options_trust_proxy)
    HBOX_OPTIONS_HOSTNAME                = var.homebox_config.options_hostname
    HBOX_AUTH_RATE_LIMIT_ENABLED         = tostring(var.homebox_config.auth_rate_limit_enabled)
    HBOX_AUTH_RATE_LIMIT_MAX_ATTEMPTS    = tostring(var.homebox_config.auth_rate_limit_max_attempts)
    HBOX_AUTH_RATE_LIMIT_WINDOW          = var.homebox_config.auth_rate_limit_window
    HBOX_AUTH_RATE_LIMIT_BASE_BACKOFF    = var.homebox_config.auth_rate_limit_base_backoff
    HBOX_AUTH_RATE_LIMIT_MAX_BACKOFF     = var.homebox_config.auth_rate_limit_max_backoff
    HBOX_DEBUG_ENABLED                   = tostring(var.homebox_config.debug_enabled)
    HBOX_DEBUG_PORT                      = tostring(var.homebox_config.debug_port)
    HBOX_DEMO                            = tostring(var.homebox_config.demo)
    HBOX_OIDC_ENABLED                    = tostring(var.homebox_config.oidc_enabled)
    HBOX_OIDC_ISSUER_URL                 = var.homebox_config.oidc_issuer_url
    HBOX_OIDC_CLIENT_ID                  = var.homebox_config.oidc_client_id
    HBOX_OIDC_CLIENT_SECRET              = var.homebox_config.oidc_client_secret
    HBOX_OIDC_SCOPE                      = var.homebox_config.oidc_scope
    HBOX_OIDC_ALLOWED_GROUPS             = var.homebox_config.oidc_allowed_groups
    HBOX_OIDC_AUTO_REDIRECT              = tostring(var.homebox_config.oidc_auto_redirect)
    HBOX_OIDC_VERIFY_EMAIL               = tostring(var.homebox_config.oidc_verify_email)
    HBOX_OIDC_GROUP_CLAIM                = var.homebox_config.oidc_group_claim
    HBOX_OIDC_EMAIL_CLAIM                = var.homebox_config.oidc_email_claim
    HBOX_OIDC_NAME_CLAIM                 = var.homebox_config.oidc_name_claim
    HBOX_OIDC_EMAIL_VERIFIED_CLAIM       = var.homebox_config.oidc_email_verified_claim
    HBOX_OIDC_BUTTON_TEXT                = var.homebox_config.oidc_button_text
    HBOX_OIDC_STATE_EXPIRY               = var.homebox_config.oidc_state_expiry
    HBOX_OIDC_REQUEST_TIMEOUT            = var.homebox_config.oidc_request_timeout
    HBOX_THUMBNAIL_ENABLED               = tostring(var.homebox_config.thumbnail_enabled)
    HBOX_THUMBNAIL_WIDTH                 = tostring(var.homebox_config.thumbnail_width)
    HBOX_THUMBNAIL_HEIGHT                = tostring(var.homebox_config.thumbnail_height)
  }

  homebox_environment_variables = merge(
    {
      for key, value in local.homebox_environment_defaults : key => value
      if value != null
    },
    var.homebox_environment_overrides,
  )
}

resource "proxmox_virtual_environment_oci_image" "homebox" {
  node_name           = var.target_node
  datastore_id        = var.template_storage
  reference           = "${var.container_repository}:${var.container_tag}"
  overwrite           = true
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "homebox" {
  description   = var.description
  node_name     = var.target_node
  vm_id         = var.vmid
  pool_id       = var.pool_id
  tags          = var.tags
  started       = var.started
  start_on_boot = var.start_on_boot
  unprivileged  = var.unprivileged

  cpu {
    architecture = var.cpu.architecture
    cores        = var.cpu.cores
    units        = var.cpu.units
  }

  disk {
    datastore_id = var.rootfs.storage
    size         = var.rootfs.size
  }

  mount_point {
    volume = var.data_mount.storage
    size   = var.data_mount.size
    path   = var.data_mount.path
  }

  memory {
    dedicated = var.memory.dedicated
    swap      = var.memory.swap
  }

  network_interface {
    name        = var.network_interface_name
    bridge      = var.network_bridge
    firewall    = var.network_firewall
    mac_address = var.mac_address == "" ? null : var.mac_address
    mtu         = var.network_mtu
    vlan_id     = var.network_vlan_id
  }

  initialization {
    entrypoint = var.entrypoint
    hostname   = var.host_name

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.gateway_ip
      }
    }
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_oci_image.homebox.id
    type             = "unmanaged"
  }

  environment_variables = local.homebox_environment_variables

  wait_for_ip {
    ipv4 = var.started && var.wait_for_ipv4
  }
}
