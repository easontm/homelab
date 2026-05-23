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
# Valkey
##############
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
