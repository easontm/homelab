variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Kubernetes namespace for paperless-ngx"
  type        = string
  default     = "paperless-ngx"
}

variable "ingress_namespaces" {
  description = "List of namespaces allowed to reference paperless-ngx services via ReferenceGrant"
  type        = list(string)
  default     = []
}

variable "postgres_password" {
  description = "Password for PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "nfs_storage_class_name" {
  description = "NFS storage class name for webserver PVCs (data, media, export)"
  type        = string
  default     = ""
}

variable "consume_storage_class_name" {
  description = "Storage class name for the consume PVC on the webserver."
  type        = string
  default     = ""
}

variable "iscsi_storage_class_name" {
  description = "iSCSI storage class name for database and broker PVCs"
  type        = string
  default     = ""
}

# Container images
variable "postgres_image" {
  description = "PostgreSQL container image"
  type        = string
  default     = "docker.io/library/postgres:18"
}

variable "redis_image" {
  description = "Redis container image"
  type        = string
  default     = "docker.io/library/redis:8"
}

variable "paperless_ngx_image" {
  description = "Paperless-ngx container image"
  type        = string
  default     = "ghcr.io/paperless-ngx/paperless-ngx:latest"
}

variable "tika_image" {
  description = "Tika container image"
  type        = string
  default     = "docker.io/apache/tika:latest"
}

variable "gotenberg_image" {
  description = "Gotenberg container image"
  type        = string
  default     = "docker.io/gotenberg/gotenberg:8.24"
}

# Storage sizes
variable "db_storage_size" {
  description = "Storage size for PostgreSQL database"
  type        = string
  default     = "100Mi"
}

variable "broker_storage_size" {
  description = "Storage size for Redis broker"
  type        = string
  default     = "100Mi"
}

variable "webserver_replicas" {
  description = "Number of replicas for the paperless-ngx webserver Deployment"
  type        = number
  default     = 1
}

variable "webserver_data_storage_size" {
  description = "Storage size for webserver data"
  type        = string
  default     = "100Mi"
}

variable "webserver_media_storage_size" {
  description = "Storage size for webserver media"
  type        = string
  default     = "100Mi"
}

variable "webserver_export_storage_size" {
  description = "Storage size for webserver export"
  type        = string
  default     = "100Mi"
}

variable "webserver_consume_storage_size" {
  description = "Storage size for webserver consume"
  type        = string
  default     = "100Mi"
}

# Backup configuration
variable "backup_enabled" {
  description = "Enable paperless-ngx document exporter backup CronJob"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron schedule for document exporter backups (default: daily at 2am)"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_retention_days" {
  description = "Number of days to retain export zip files before cleanup"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1
    error_message = "backup_retention_days must be at least 1."
  }
}

variable "backup_storage_size" {
  description = "Storage size for the NFS backup export PVC"
  type        = string
  default     = "20Gi"
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

# Paperless-ngx environment variables
variable "paperless_env_vars" {
  description = "Additional environment variables for paperless-ngx webserver"
  type        = map(string)
  default     = {}
}
