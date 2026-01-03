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

variable "postgres_password" {
  description = "Password for PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "nfs_storage_class_name" {
  description = "NFS storage class name for webserver PVCs (data, media, export, consume)"
  type        = string
  default     = "nfs-retain"
}

variable "iscsi_storage_class_name" {
  description = "iSCSI storage class name for database and broker PVCs"
  type        = string
  default     = "iscsi-retain"
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

# Paperless-ngx environment variables
variable "paperless_env_vars" {
  description = "Additional environment variables for paperless-ngx webserver"
  type        = map(string)
  default     = {}
}
