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
variable "values_files" {
  description = <<-EOT
    List of paths to Helm values YAML files. Files are loaded in order, with later files taking
    precedence over earlier ones (standard Helm merge behaviour). Write your Authelia chart config
    here — see https://github.com/authelia/chartrepo/blob/master/charts/authelia/values.yaml for
    the full reference. Do not put secrets in these files.
  EOT
  type        = list(string)
  default     = []
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
