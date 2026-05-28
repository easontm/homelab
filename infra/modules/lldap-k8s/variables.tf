##############
# Kubernetes
##############
variable "kubeconfig_paths" {
  description = "List of paths to kubeconfig files"
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Kubernetes namespace for LLDAP"
  type        = string
  default     = "lldap"
}

variable "ingress_namespaces" {
  description = "List of namespaces allowed to reference the LLDAP web service via ReferenceGrant (e.g., [\"traefik\"])"
  type        = list(string)
  default     = []
}

##############
# Image
##############
variable "lldap_image_repository" {
  description = "LLDAP container image repository"
  type        = string
  default     = "lldap/lldap"
}

variable "lldap_image_tag" {
  description = "LLDAP container image tag"
  type        = string
  default     = "stable"
}

##############
# LLDAP configuration
##############
variable "ldap_base_dn" {
  description = "LDAP base distinguished name, e.g. dc=example,dc=com"
  type        = string
}

variable "jwt_secret" {
  description = "Secret used to sign JWT tokens. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

variable "key_seed" {
  description = "Seed used for private key generation. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Password for the LLDAP admin user (username: admin)"
  type        = string
  sensitive   = true
}

variable "lldap_env_vars" {
  description = "Additional LLDAP environment variables. Keys should use the LLDAP_ prefix. Credentials and secrets are set automatically and should not be included here."
  type        = map(string)
  default     = {}
}

##############
# Storage
##############
variable "storage_class_name" {
  description = "Storage class for the LLDAP data PVC. SQLite has known issues over NFS — prefer an iSCSI-backed class."
  type        = string
}

variable "data_storage_size" {
  description = "Size of the LLDAP data PVC (holds the SQLite database and config)"
  type        = string
  default     = "1Gi"
}

##############
# Resource sizing
##############
variable "lldap_resources" {
  description = "CPU and memory resource limits and requests for the LLDAP container"
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
      memory = "256Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}

##############
# Runtime user
##############
variable "uid" {
  description = "UID to run the LLDAP container as. Use 1000 for the rootless image (lldap/lldap:<tag>-rootless)."
  type        = number
  default     = 1000
}

variable "gid" {
  description = "GID to run the LLDAP container as, and for fsGroup on the data PVC. Use 1000 for the rootless image."
  type        = number
  default     = 1000
}

##############
# Bootstrap
##############
variable "bootstrap_enabled" {
  description = "Run a one-shot Kubernetes Job after LLDAP starts to seed users and groups using bootstrap.sh"
  type        = bool
  default     = false
}

variable "bootstrap_user_configs" {
  description = "Map of filename to JSON content for bootstrap user config files (mounted at /bootstrap/user-configs). Each map value must be a single JSON object (not an array) — use one key per user. Example: { \"alice.json\" = jsonencode({ id = \"alice\", email = \"alice@example.com\", groups = [\"lldap_admin\"] }) }"
  type        = map(string)
  default     = {}
}

variable "bootstrap_group_configs" {
  description = "Map of filename to JSON content for bootstrap group config files (mounted at /bootstrap/group-configs). Each map value must be a single JSON object (not an array) — use one key per group. Example: { \"admins.json\" = jsonencode({ name = \"lldap_admin\" }) }"
  type        = map(string)
  default     = {}
}
