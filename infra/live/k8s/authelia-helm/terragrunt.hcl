include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/authelia-helm"
}

locals {
  secrets = yamldecode(sops_decrypt_file("./authelia_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  ingress_namespaces = ["traefik"]

  chart_version = "0.11.5"  # Authelia 4.39.19

  # Valkey (Redis fork) for session storage
  valkey_enabled       = true
  valkey_chart_version = "0.9.4"
  valkey_storage_class = "iscsi-retain"
  valkey_storage_size  = "256Mi"
  # valkey_password = local.secrets.valkey_password  # optional; add to sops if auth is desired

  # PostgreSQL for persistent storage
  db_type               = "postgres"
  db_storage_class      = "iscsi-retain"
  db_storage_size       = "2Gi"
  postgres_password     = local.secrets.postgres_password
  backup_enabled        = false
  backup_storage_class  = "nfs-retain"
  backup_storage_size   = "5Gi"

  # LLDAP as the authentication backend.
  # The module auto-wires the LDAP configMap block and disables the file backend.
  lldap_enabled  = true
  lldap_address  = "ldap://lldap-ldap.lldap.svc.cluster.local:3890"
  lldap_base_dn  = local.secrets.lldap_base_dn
  lldap_user     = local.secrets.lldap_user
  lldap_password = local.secrets.lldap_password

  values_files = ["${get_terragrunt_dir()}/values.yaml"]

  # Secrets are generated from sops at plan-time as a YAML string.
  # Later values_files entries and this value override earlier ones.
  # NOTE: authelia_vars.sops.yaml must contain:
  #   session_encryption_key, storage_encryption_key, jwt_secret,
  #   smtp_password (optional), lldap_base_dn, lldap_user, lldap_password.
  sensitive_values_yaml = yamlencode({
    configMap = {
      identity_validation = {
        reset_password = {
          secret = { value = local.secrets.jwt_secret }
        }
      }
      # session = {
      #   encryption_key = { value = local.secrets.session_encryption_key }
      # }
      storage = {
        encryption_key = { value = local.secrets.storage_encryption_key }
      }
      notifier = {
        smtp = {
          username = local.secrets.domain
          password = { value = local.secrets.smtp_password }
          sender = "Authelia <authelia@${local.secrets.domain}>"
        }
      }
    }
  })
}
