output "namespace" {
  description = "Kubernetes namespace where LLDAP is deployed"
  value       = kubernetes_namespace_v1.lldap.metadata[0].name
}

output "web_service_name" {
  description = "Name of the Kubernetes Service for the LLDAP web UI (port 17170)"
  value       = kubernetes_service_v1.lldap_web.metadata[0].name
}

output "ldap_service_name" {
  description = "Name of the Kubernetes Service for the LLDAP LDAP port (3890)"
  value       = kubernetes_service_v1.lldap_ldap.metadata[0].name
}
