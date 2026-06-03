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

  values_files = ["${get_terragrunt_dir()}/values.yaml"]

  # Secrets are generated from sops at plan-time as a YAML string.
  # Later values_files entries and this value override earlier ones.
  # NOTE: authelia_vars.sops.yaml must contain:
  #   session_encryption_key, storage_encryption_key, jwt_secret,
  #   smtp_password (optional), and a users list.
  sensitive_values_yaml = yamlencode({
    # Create a K8s Secret containing the users database YAML. Mounted by the pod
    # via pod.extraVolumes / pod.extraVolumeMounts defined in values.yaml.
    extraObjects = [
      {
        apiVersion = "v1"
        kind       = "Secret"
        metadata = {
          name      = "authelia-users-db"
          namespace = "authelia"
        }
        stringData = {
          "users_database.yml" = yamlencode({
            users = {
              for u in local.secrets.users : u.username => {
                displayname = u.display_name
                password    = u.password
                email       = u.email
                groups      = u.groups
              }
            }
          })
        }
      }
    ]

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
