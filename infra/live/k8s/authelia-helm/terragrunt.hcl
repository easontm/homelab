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
  timeout = 60

  chart_version = "0.11.6"  # Authelia 4.39.19

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
  # The module auto-wires the LDAP configMap block using the "lldap" implementation preset.
  auth_backend   = "lldap"
  lldap_address  = "ldap://lldap-ldap.lldap.svc.cluster.local:3890"
  lldap_base_dn  = local.secrets.lldap_base_dn
  lldap_user     = local.secrets.lldap_user
  lldap_password = local.secrets.lldap_password
  # The module creates the users_database.yml Secret and mounts it automatically.
  # file_auth_users   = local.secrets.users

  helm_values = templatefile(
    "${get_terragrunt_dir()}/values.yaml",
    {
      domain = local.secrets.domain
      oidc_hmac_secret = local.secrets.oidc.hmac_secret
      jwks_private_key = local.secrets.oidc.jwks_private_key
    }
  )
  sensitive_values_yaml = yamlencode({
    pod = {
      env = [
        { name = "DOMAIN", value = local.secrets.domain }
      ]
    }
    configMap = {
      identity_validation = {
        reset_password = {
          secret = { value = local.secrets.jwt_secret }
        }
      }
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
