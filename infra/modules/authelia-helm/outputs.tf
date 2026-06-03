output "namespace" {
  description = "Kubernetes namespace where Authelia is deployed"
  value       = kubernetes_namespace_v1.authelia.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.authelia.name
}

output "chart_version" {
  description = "Deployed Authelia Helm chart version"
  value       = helm_release.authelia.version
}

output "valkey_service_host" {
  description = "In-cluster hostname of the Valkey service, or null when valkey_enabled is false"
  value       = var.valkey_enabled ? "valkey.${kubernetes_namespace_v1.authelia.metadata[0].name}.svc.cluster.local" : null
}

output "postgres_service_host" {
  description = "In-cluster hostname of the PostgreSQL service, or null when db_type is not 'postgres'"
  value       = local.postgres_enabled ? local.postgres_service_host : null
}
