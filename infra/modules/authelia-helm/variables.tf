##############
# Kubernetes
##############
variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Kubernetes namespace for Authelia"
  type        = string
  default     = "authelia"
}

variable "ingress_namespaces" {
  description = "List of namespaces allowed to reference the Authelia service via ReferenceGrant"
  type        = list(string)
  default     = []
}

##############
# Helm
##############
variable "chart_version" {
  description = "Version of the Authelia Helm chart to deploy. Pin this to avoid unexpected upgrades."
  type        = string
}

variable "timeout" {
  description = "Helm release timeout in seconds"
  type        = number
  default     = 300
}

##############
# Values
##############
variable "helm_values" {
  description = <<-EOT
    A string of of Helm values. This will be merged with values from other configurations (such as
    Valkey, Postgres, LLDAP, etc), but takes precedence over them. This is useful for generating
    values from variables at plan-time, especially secrets from sops. For example:

      helm_values = templatefile(
        "$\{get_terragrunt_dir()}/values.yaml",
        {
          domain = local.secrets.domain
        }
      )
  EOT
  # type        = map(any)
  type    = string
  default = ""
}

variable "sensitive_values_yaml" {
  description = <<-EOT
    A YAML string containing sensitive Helm values that should not be stored on disk. This is merged
    after all values_files so it takes final precedence. Generate this in your terragrunt.hcl with
    yamlencode() from sops-decrypted variables. For example:

      sensitive_values_yaml = yamlencode({
        configMap = {
          session = {
            encryption_key = { value = local.secrets.session_encryption_key }
          }
          storage = {
            encryption_key = { value = local.secrets.storage_encryption_key }
          }
        }
      })

    See https://github.com/authelia/chartrepo/tree/master/charts/authelia for the full schema.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

##############
# Database
##############
variable "db_type" {
  description = "Database backend for Authelia. 'sqlite' uses local file storage; 'postgres' deploys an in-cluster PostgreSQL pod."
  type        = string
  default     = "sqlite"

  validation {
    condition     = contains(["sqlite", "postgres"], var.db_type)
    error_message = "db_type must be either 'sqlite' or 'postgres'."
  }
}

variable "db_storage_class" {
  description = "StorageClass for the PostgreSQL PVC. Only used when db_type is 'postgres'."
  type        = string
  default     = ""
}

variable "db_storage_size" {
  description = "Size of the PostgreSQL PVC (e.g. '5Gi'). Only used when db_type is 'postgres'."
  type        = string
  default     = "5Gi"
}

variable "postgres_image" {
  description = "PostgreSQL container image. Only used when db_type is 'postgres'."
  type        = string
  default     = "docker.io/library/postgres:17"
}

variable "postgres_user" {
  description = "PostgreSQL username for Authelia. Only used when db_type is 'postgres'."
  type        = string
  default     = "authelia"

  validation {
    condition     = var.db_type != "postgres" || trimspace(var.postgres_user) != ""
    error_message = "postgres_user must not be empty when db_type is 'postgres'."
  }
}

variable "postgres_password" {
  description = "PostgreSQL password for Authelia. Required when db_type is 'postgres'. Supply from sops."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.db_type != "postgres" || (var.postgres_password != null && trimspace(var.postgres_password) != "")
    error_message = "postgres_password must be set when db_type is 'postgres'."
  }
}

variable "postgres_database_name" {
  description = "PostgreSQL database name. Only used when db_type is 'postgres'."
  type        = string
  default     = "authelia"

  validation {
    condition     = var.db_type != "postgres" || trimspace(var.postgres_database_name) != ""
    error_message = "postgres_database_name must not be empty when db_type is 'postgres'."
  }
}

variable "postgres_resources" {
  description = "CPU and memory resource limits and requests for the PostgreSQL container. Only used when db_type is 'postgres'."
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
  }
}

##############
# Backup
##############
variable "backup_enabled" {
  description = "Enable the pg_dump backup CronJob. Only takes effect when db_type is 'postgres'."
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron schedule for the pg_dump backup job."
  type        = string
  default     = "0 2 * * *"
}

variable "backup_storage_class" {
  description = "StorageClass for the backup PVC. Defaults to db_storage_class."
  type        = string
  default     = ""
}

variable "backup_storage_size" {
  description = "Size of the backup PVC (e.g. '10Gi')."
  type        = string
  default     = "10Gi"
}

variable "backup_retention_days" {
  description = "Number of days to retain pg_dump files."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1
    error_message = "backup_retention_days must be at least 1."
  }
}

variable "backup_successful_jobs_history_limit" {
  description = "Number of successful backup jobs to retain in history."
  type        = number
  default     = 3
}

variable "backup_failed_jobs_history_limit" {
  description = "Number of failed backup jobs to retain in history."
  type        = number
  default     = 3
}

##############
# Authentication backend
##############
variable "auth_backend" {
  description = "Which authentication backend Authelia should use. Authelia supports exactly one backend at a time. Use 'file' for a local users_database.yml (supply file_auth_users), or 'lldap' for an LLDAP LDAP backend (supply lldap_* variables). Omit or set to null to leave backend configuration entirely to values_files / sensitive_values_yaml."
  type        = string
  default     = null

  validation {
    condition     = var.auth_backend == null || contains(["file", "lldap"], var.auth_backend)
    error_message = "auth_backend must be one of: \"file\", \"lldap\", or null."
  }
}

variable "file_auth_users" {
  description = <<-EOT
    List of users to write into the Authelia users_database.yml file backend.
    Each entry requires: username, display_name, password (hashed), email, groups (list of strings).
    Passwords must be pre-hashed (argon2id recommended). Only used when auth_backend is "file".
    Supply from sops — this is sensitive.

    Example sops YAML:
      users:
        - username: alice
          display_name: Alice
          password: "$argon2id$v=19$m=65536,t=3,p=4$..."
          email: alice@example.com
          groups: [admins]
  EOT
  type = list(object({
    username     = string
    display_name = string
    password     = string
    email        = string
    groups       = list(string)
  }))
  default   = []
  sensitive = true
}

##############
# LLDAP
##############

variable "lldap_address" {
  description = "LDAP address for LLDAP (e.g. 'ldap://lldap-ldap.lldap.svc.cluster.local:3890'). Only used when auth_backend is \"lldap\"."
  type        = string
  default     = ""
}

variable "lldap_base_dn" {
  description = "LDAP base distinguished name (e.g. 'dc=example,dc=com'). Only used when auth_backend is \"lldap\"."
  type        = string
  default     = ""
}

variable "lldap_user" {
  description = "Full bind DN of the LLDAP service account used by Authelia (e.g. 'uid=authelia,ou=people,dc=example,dc=com'). Only used when auth_backend is \"lldap\"."
  type        = string
  default     = ""
}

variable "lldap_password" {
  description = "Password for the LLDAP bind user. Supply from sops. Only used when auth_backend is \"lldap\"."
  type        = string
  default     = null
  sensitive   = true
}

variable "valkey_enabled" {
  description = "Deploy a Valkey instance (official Redis fork, BSD-licensed) for Authelia session storage. When true, Authelia's session redis config is auto-wired."
  type        = bool
  default     = false
}

variable "valkey_chart_version" {
  description = "Version of the valkey-io/valkey-helm chart to deploy. See https://github.com/valkey-io/valkey-helm for releases."
  type        = string
  default     = "0.9.4"
}

variable "valkey_storage_class" {
  description = "StorageClass for the Valkey PersistentVolumeClaim. Leave empty to use the cluster default."
  type        = string
  default     = ""
}

variable "valkey_storage_size" {
  description = "Size of the Valkey PersistentVolumeClaim (e.g. '256Mi'). Set to empty string to disable persistence."
  type        = string
  default     = "256Mi"
}

variable "valkey_password" {
  description = "Optional password for the Valkey 'default' ACL user. If null, authentication is disabled (suitable for in-cluster use with network policies). Supply from sops."
  type        = string
  default     = null
  sensitive   = true
}

##############
# OIDC
##############
variable "oidc_hmac_secret" {
  description = "HMAC secret used by Authelia to sign OIDC tokens. Generate with: openssl rand -hex 64. Supply from sops. If null, OIDC is not configured by the module."
  type        = string
  default     = null
  sensitive   = true
}

variable "oidc_jwks_private_key" {
  description = "RSA private key (PEM format) used by Authelia as the OIDC JWK signing key. Generate with: openssl genrsa 4096. Include the full PEM block. Supply from sops. If null, OIDC is not configured by the module."
  type        = string
  default     = null
  sensitive   = true
}
