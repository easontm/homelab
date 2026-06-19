##############
# Kubernetes
##############
variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Kubernetes namespace for Homebox"
  type        = string
  default     = "homebox"
}

variable "ingress_namespaces" {
  description = "List of namespaces allowed to reference the Homebox service via ReferenceGrant"
  type        = list(string)
  default     = []
}

##############
# Image
##############
variable "homebox_image_repository" {
  description = "Homebox container image repository"
  type        = string
  default     = "sysadminsmedia/homebox"
}

variable "homebox_image_tag" {
  description = "Homebox container image tag"
  type        = string
  default     = "latest"
}

##############
# Database
##############
variable "db_type" {
  description = "Database backend for Homebox. Use sqlite for the default single-pod deployment or postgres to provision a separate PostgreSQL pod."
  type        = string
  default     = "sqlite"

  validation {
    condition     = contains(["sqlite", "postgres"], var.db_type)
    error_message = "db_type must be either sqlite or postgres."
  }
}

##############
# HomeBox configuration
##############
variable "homebox_env_vars" {
  description = "Additional Homebox environment variables passed to the container. Keys should match HBOX_* envvar names expected by the application. Database-related HBOX_DATABASE_* vars are set automatically based on db_type and should not be included here."
  type        = map(string)
  default     = {}
}

##############
# Storage
##############
variable "storage_class_name" {
  description = "Storage class name for the Homebox data PVC"
  type        = string
  default     = ""
}

variable "data_storage_size" {
  description = "Storage size for the Homebox data PVC"
  type        = string
  default     = "5Gi"
}

variable "db_storage_class_name" {
  description = "Storage class name for the PostgreSQL data PVC. Defaults to storage_class_name."
  type        = string
  default     = null
}

variable "db_storage_size" {
  description = "Storage size for the PostgreSQL data PVC. Only used when db_type is postgres."
  type        = string
  default     = "5Gi"
}

##############
# Resource sizing
##############
variable "homebox_resources" {
  description = "CPU and memory resource limits and requests for the Homebox container"
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
      cpu    = "50m"
      memory = "128Mi"
    }
  }
}

variable "postgres_resources" {
  description = "CPU and memory resource limits and requests for the PostgreSQL container. Only used when db_type is postgres."
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
  description = "Enable the PostgreSQL pg_dump backup CronJob. Only takes effect when db_type is postgres."
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron schedule for the pg_dump backup job (default: daily at 2am)"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_storage_class_name" {
  description = "Storage class name for the backup PVC. Defaults to storage_class_name."
  type        = string
  default     = null
}

variable "backup_storage_size" {
  description = "Storage size for the backup PVC"
  type        = string
  default     = "5Gi"
}

variable "backup_retention_days" {
  description = "Number of days to retain pg_dump files before cleanup"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1
    error_message = "backup_retention_days must be at least 1."
  }
}

variable "backup_successful_jobs_history_limit" {
  description = "Number of successful backup jobs to retain in history"
  type        = number
  default     = 3
}

variable "backup_failed_jobs_history_limit" {
  description = "Number of failed backup jobs to retain in history"
  type        = number
  default     = 1
}

variable "postgres_image" {
  description = "PostgreSQL container image. Only used when db_type is postgres."
  type        = string
  default     = "docker.io/library/postgres:18"
}

variable "postgres_user" {
  description = "PostgreSQL username. Shared between the PostgreSQL pod initialization and the Homebox connection settings."
  type        = string
  default     = "homebox"

  validation {
    condition     = var.db_type != "postgres" || trimspace(var.postgres_user) != ""
    error_message = "postgres_user must not be empty when db_type is postgres."
  }
}

variable "postgres_password" {
  description = "PostgreSQL password. Required when db_type is postgres. Stored in a Kubernetes Secret."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.db_type != "postgres" || (var.postgres_password != null && trimspace(var.postgres_password) != "")
    error_message = "postgres_password must be set when db_type is postgres."
  }
}

variable "postgres_database_name" {
  description = "PostgreSQL database name. Shared between the PostgreSQL pod initialization and the Homebox connection settings."
  type        = string
  default     = "homebox"

  validation {
    condition     = var.db_type != "postgres" || trimspace(var.postgres_database_name) != ""
    error_message = "postgres_database_name must not be empty when db_type is postgres."
  }
}

##############
# OIDC
##############
variable "oidc_client_secret" {
  description = "Raw (unhashed) OIDC client secret for Homebox to authenticate against Authelia. When set, a Kubernetes Secret is created with HBOX_OIDC_CLIENT_SECRET and injected into the Homebox container via a dynamic env block. Supply from sops. If null, OIDC is not configured by the module."
  type        = string
  default     = null
  sensitive   = true
}
