output "bundle" {
  description = "Installed bundle pin."
  value       = var.bundle
}

output "resource_keys" {
  description = "Stable Kind/name resource identities in this bundle."
  value       = sort(keys(kubernetes_manifest.resource))
}
